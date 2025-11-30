# Agent Orchestration & Architecture
---

## Table of Contents

- [Architecture overview](#architecture-overview)
- [Agent management](#agent-management)
- [Routing](#routing)
- [Validation](#validation)
- [AgentDomain](#agentdomain)
- [Agents](#agents)
- [AgentInfrastructure, Memory and Token ownership](#agentinfrastructure-memory-and-token-ownership)
- [Concurrency](#concurrency)

---

## Architecture overview

### Core concepts

- **Agent**  
  Autonomous component that:
  - wraps an LLM model,
  - may own tools (external systems / APIs),
  - interacts with memory,
  - has a `TypeOfAgent` and clear domain semantics (e.g. RAG, Cloud Logging).

- **AgentManager**  
  Orchestrator responsible for:
  - deciding which agents should run for a given request,
  - executing them through a LangGraph state machine,
  - combining their outputs into a final answer.

- **Route**  
  Routing strategy that:
  - inspects the current `ManagerState` (query, requests, results so far),
  - inspects which agents are available,
  - returns a `RouteDecision`, which determines which node(s) in the graph will run.

- **AgentInfrastructure**  
  Technical infrastructure, providing:
  - `TokenManager` – token accounting and limits,
  - `AgentMemoryManager` – conversation/memory handling.

- **AgentDomain**  
  Domain-level types:
  - `AgentParams` implementations (e.g. `CLSParams`),
  - `AgentRequest` – a request to a specific agent with parameters.

### High-level request flow

1. A user sends a query via HTTP (view / interaction layer).
2. The view constructs zero or more `AgentRequest` instances and calls:
   ```python
   AgentManager.run(query, thread_id, agent_requests, config)
   ```
3. `AgentManager`:
   - creates an initial `ManagerState`,
   - feeds it into a compiled LangGraph graph built from a `Route`.
4. Manager nodes in the graph are invoked:
   - `CloudNode` executes `CLSAgent`,
   - `RagNode` executes `RAGAgent`,
   - `FinalizeNode` combines results into a final answer.
5. The graph returns a final `ManagerState` that contains:
   - `results` – per-agent outputs,
   - `final_answer` – the chosen text answer,
   - `tokens_used` – total tokens spent.
6. The view returns `final_answer` (and optionally more detail) to the user.

---

## Agent management

### AgentManager

`AgentManager` is the high-level entry point for orchestration.

Responsibilities:

- Owns an `AgentInfrastructure` instance.
- Creates an `AgentRegistry` that registers all active agents based on `AGENT_MAP`.
- Uses a `RouteFactory` to construct a `Route` (e.g. `DefaultRoute`).
- Uses `AgentGraphBuilder` to construct and compile a LangGraph state graph.
- Exposes a single main method:

```python
def run(self, query: str, thread_id: str, 
agent_requests: list[AgentRequest] | None = None config: dict | None = None) -> dict:
    ...
```

This method:

1. Validates its arguments via `AgentManagementValidator`.
2. Prepares an initial `ManagerState`:
   - `query`
   - `thread_id`
   - `agent_requests`
   - `results` (empty dict)
   - `tokens_used` (0)
3. Invokes the compiled LangGraph graph with this state and config.
4. Returns the final state as a plain dictionary (results, tokens, final answer).

### AgentRegistry

`AgentRegistry` centralizes agent creation and lookup.

On initialization:

- Reads a config map `AGENT_MAP: dict[TypeOfAgent, bool]`.
- For each active `TypeOfAgent`, calls `AgentFactory.create(type, infrastructure)`.
- Stores the result in an internal mapping `dict[TypeOfAgent, Agent]`.

It exposes:

```python
registry.get(TypeOfAgent.CLS_AGENT)
registry.try_get(TypeOfAgent.RAG_AGENT)
registry.has(TypeOfAgent.RAG_AGENT)
registry.agents  # full mapping of TypeOfAgent -> Agent
```

This means `AgentManager`, nodes and routes never know *how* an agent is constructed – they simply ask the registry.

### Manager nodes

Manager nodes are small classes that implement a common interface:

```python
class ManagerNode(ABC):
    name: str

    def __call__(self, state: ManagerState) -> ManagerState:
        ...
```

Main nodes:

- **RouteNode** (`"route"`)  
  Entry node. It simply passes the state through. The actual routing happens via LangGraph `conditional_edges` using the `Route.decision` logic.

- **CloudNode** (`"cloud"`)  
  - Validates that the state has `query` and `thread_id`.
  - Resolves `CLSAgent` from `AgentRegistry`.
  - Extracts `CLSParams` for CLS from `agent_requests`, if present.
  - Executes `cls_agent.run(...)`.
  - Stores the result under `state["results"][TypeOfAgent.CLS_AGENT]`.
  - Updates `state["tokens_used"]` via `TokenManager`.

- **RagNode** (`"rag"`)  
  - Similar to `CloudNode`, but uses `RAGAgent` instead.

- **FinalizeNode** (`"finalize"`)  
  - Inspects `state["results"]` and selects which agent result becomes `final_answer` (e.g. prefer CLS over RAG).
  - Copies `tokens_used` into the final state.
  - Ensures `final_answer` is always present in the final ManagerState.

This node-based approach keeps each step focused and testable.

---

## Routing

### Route abstraction

`Route` describes the control flow logic on top of the LangGraph state machine.

Key methods:

```python
class Route(ABC):
    def decision(self, state: ManagerState, agents: AgentRegistry) -> RouteDecision:
        ...

    def mapping(self) -> dict[RouteDecision, str]:
        ...

    def edges(self) -> list[tuple[str, str]]:
        ...

    def wire(self, graph: StateGraph,
        node_factory: ManagerNodeFactory, agents: AgentRegistry) -> None:
        ...
```

- **`decision`** – inspects `state` and available agents (`AgentRegistry`) and returns a `RouteDecision` (e.g. `RAG_DECISION`, `CLS_DECISION`).
- **`mapping`** – maps each `RouteDecision` to a node name (e.g. `RAG_DECISION -> "rag"`).
- **`edges`** – returns the static edges, e.g. `("cloud", "finalize")`.
- **`wire`** – wires nodes and edges into a `StateGraph` and adds a conditional edge from `"route"` node using `decision` and `mapping`.

### DefaultRoute

`DefaultRoute` is the main routing strategy.

`decision(state, agents)`:

1. Validates `state` and `agents` using `DefaultRouteValidator`.
2. Checks which agents are available via `AgentRegistry`:
   - `has(TypeOfAgent.CLS_AGENT)`
   - `has(TypeOfAgent.RAG_AGENT)`
3. Looks at `agent_requests`:
   - explicit requests for CLS or RAG.
4. Combines this information into a `RouteDecision`:
   - if both CLS and RAG are explicitly requested and available → `RAG_CLS_DECISION`
   - if only CLS is requested and available → `CLS_DECISION`
   - if only RAG is requested and available → `RAG_DECISION`
   - if there are no explicit requests, but RAG exists → default to `RAG_DECISION`
   - otherwise → `NO_DECISION` (go directly to `finalize`)

`mapping()` then ensures that:

- `RAG_DECISION` → `"rag"`
- `CLS_DECISION` → `"cloud"`
- `RAG_CLS_DECISION` → e.g. `"cloud"` first, then static edge to `"rag"` or vice versa
- `NO_DECISION` → `"finalize"`

In this way all routing logic lives in `DefaultRoute`. Swapping routing strategies means swapping the `Route` implementation without touching agents or the manager.

---

## Validation

### Validator and Rule

The validation layer is generic and reusable.

- **`Validator`**  
  - Registers rules per stage (e.g. `"init"`, `"run_args"`, `"decision"`, `"params"`).
  - `validate(stage, *args)`:
    - executes all `Rule` instances for that stage,
    - if any rule returns `False`, it records the error message and stops,
    - returns `True` or `False`,
    - `get_last_error()` returns the last error message.

- **`Rule`**  
  - Wraps a callable and an error message:
    ```python
    Rule(self.__check_something, "some error message")
    ```

### Concrete validators

- **`AgentManagementValidator`**
  - `init` – validates that:
    - `route` is non-null and has the expected interface,
    - the agent mapping is a dict of `TypeOfAgent -> Agent`.
  - `run_args` – validates:
    - `query` is a string,
    - `thread_id` is a non-empty string,
    - `agent_requests` is a list or `None`,
    - `config` is a dict or `None`.
  - `state_for_node` – validates that:
    - `state` is a dict,
    - it contains required keys (e.g. `"query"`, `"thread_id"`).
  - `call_agent` (optional) – validates that the requested agent type exists.

- **`RouteValidator` / `DefaultRouteValidator`**
  - `decision` – validates:
    - that `state` is dict-like and has at least `query` and `agent_requests`,
    - (optionally) that `requested` has the expected structure if it is used.

- **`LLMAgentValidator` + specific validators (`RAGValidator`, `CLSValidator`)**
  - `base_init` – validates basic info:
    - agent name, description, type.
  - `init` – validates:
    - the model and its config,
    - required resources (e.g. vectordb or infrastructure).
  - `run`, `process_query`, `interact` – validate arguments:
    - presence and type of required keys in `**kwargs`,
    - any required domain-specific invariants.

- **`AgentParamsValidator` + `ClsParamsValidator`**
  - `params` – validates `CLSParams`:
    - `minutes_ago` is a positive integer,
    - `message`, `app_name`, `dc_name`, `level` are `str` or `None`,
    - `exact` and `summary_mode` are booleans.

Overall, this validation layer ensures that important lifecycle steps fail early with clear, domain-focused errors, rather than random `AttributeError`/`TypeError`.

---

## AgentDomain

### AgentParams

`AgentParams` is the abstract base class for all domain parameter objects used by agents:

```python
class AgentParams(ABC):
    def to_dict(self) -> dict: ...
    def validate_params(self) -> tuple[bool, str]: ...
    def to_summary(self) -> str: ...
```

- **`to_dict()`** – serializes parameters into a dict suitable for tools / LLM prompts.
- **`validate_params()`** – calls the appropriate `AgentParamsValidator` and returns `(ok, message)`.
- **`to_summary()`** – returns a short human-readable description of the parameters (used in logging / history).

### CLSParams

`CLSParams` is the domain object for the Cloud Logging agent:

Fields:

- `minutes_ago: int`
- `message: Optional[str]`
- `exact: bool`
- `app_name: Optional[str]`
- `summary_mode: bool`
- `dc_name: Optional[str]`
- `level: Optional[str]`

Interface:

- Properties (`.minutes_ago`, `.message`, …) for convenient usage in code.
- Getter methods (`get_minutes_ago()`, `get_message()`, …) used by `ClsParamsValidator`.
- `to_summary()` – returns a human friendly description, e.g.:
  > _"[CloudLogging search] last 30 minutes – message=...; app=...; level=...; dc=...; summary_mode=True"_
- `to_dict()` – returns the exact dictionary structure required by the Kibana log tool (`params` JSON).

Note: `CLSParams` is a pure domain object and **does not** depend on web forms or any UI concepts.

### CLSParamsFormAdapter

`CLSParamsFormAdapter` decouples UI forms from domain logic.

- It converts a `CloudLoggingForm` (Flask form) into a `CLSParams` instance:

```python
params = CLSParamsFormAdapter.from_form(form)
```

- This keeps UI-specific concerns (form fields and `.data` attributes) out of the domain code.

### AgentRequest

`AgentRequest` describes a request for a particular agent:

```python
@dataclass
class AgentRequest:
    agent_type: TypeOfAgent
    params: AgentParams
```

Usage:

- The view builds a list of `AgentRequest` instances (e.g. “run CLS with these params”).
- `AgentManager` and `Route` inspect `agent_requests` to know:
  - which agents are explicitly requested,
  - which parameters should be passed into each agent’s `run()`.

---

## Agents

### Base classes: Agent / LLMAgent

- **`Agent`**  
  Abstract base with:
  - `run(query, **kwargs)`
  - `clone()`
  - `get_name()`, `get_description()`, `get_type()`

- **`LLMAgent(Agent)`**  
  LLM-specific agent that:
  - wraps a `Model` (LLM configuration + provider),
  - defines a 3-step lifecycle:
    1. `process_query(query, **kwargs) -> dict`
    2. `interact(query, processed, **kwargs) -> Any`
    3. `after_run(query, answer, processed, **kwargs) -> Any`
  - `run` orchestrates this:

    ```python
    def run(self, query: str, **kwargs: Any) -> Any:
        processed = self.process_query(query, **kwargs)
        answer = self.interact(query, processed, **kwargs)
        self.after_run(query, answer, processed, **kwargs)
        return answer
    ```

### CLSAgent – Cloud Logging agent

Responsibilities:

- Initialize a LangChain agent (`initialize_agent`) with:
  - Kibana tool (`create_kibana_log_tool`),
  - an LLM using OpenAI Functions (`AgentType.OPENAI_FUNCTIONS`).
- Work with `CLSParams` as domain parameters.
- Use helper components:
  - `CloudLoggingPromptBuilder` – constructs textual prompts that instruct the tool call and embed the `params` JSON.
  - `CLSTokenHandler` – performs token-limit pre-checks and updates `TokenManager` after calls.
  - `CloudLoggingToolRunner` – invokes the LangChain agent, capturing token usage.
  - `CloudLoggingHistoryRecorder` – writes a condensed description of the request and the answer into memory.

External interface:

```python
answer = cls_agent.run(
    query,
    thread_id_key=thread_id,
    agent_params_key=cls_params,
)
```

### RAGAgent – Retrieval-Augmented agent

Responsibilities:

- Receive `query` and `thread_id`.
- Retrieve contextual documents from a vector database.
- Build a prompt and run a LangGraph ReAct agent (`create_react_agent`).
- Use helper components:
  - `RagContextRetriever` – performs vector search and filters/normalizes the results into a global context string.
  - `RagPromptBuilder` – builds `system` and `user` messages, including date/time and retrieved context.
  - `LangGraphTokenMemoryHandler` – performs token-limit pre-checks and updates tokens based on LangGraph state, and cleans up per-thread state.

External interface:

```python
answer = rag_agent.run(
    query,
    thread_id_key=thread_id,
)
```

---

## AgentInfrastructure, Memory and Token ownership

### AgentInfrastructure

`AgentInfrastructure` is a small facade that bundles:

- `TokenManager` – token accounting and limits.
- `AgentMemoryManager` – memory / history management.

It provides:

```python
infra.TM  # token manager
infra.MM  # memory manager
```

so agents and nodes do not need to know internal implementation details.

### TokenManager

`TokenManager` tracks tokens per `session_id` / `thread_id`.

Responsibilities:

- Updating and checking token usage:
  - `update_and_check(session_id, tokens, limit)`
  - `is_over_limit(session_id, limit)`
  - `reset(session_id)`
- Integrations with LLM frameworks:
  - `update_from_callback(session_id, UsageMetadataCallbackHandler, limit)` – for LangChain.
  - `update_from_langgraph_state(session_id, state, limit)` – for LangGraph.

Ownership in practice:

- **CLSAgent**:
  - Before calling the tool: `CLSTokenHandler.pre_check_limit(thread_id)` uses `TokenManager.is_over_limit`.
  - After the agent finishes:
    - `UsageMetadataCallbackHandler` collects token usage,
    - `CLSTokenHandler.update_from_callback(thread_id, cb)` forwards info to `TokenManager`.

- **RAGAgent**:
  - Before running the graph: `LangGraphTokenMemoryHandler.pre_check_limit(thread_id)`.
  - After the graph:
    - `LangGraphTokenMemoryHandler.update_from_chain_state(chain, thread_id, config)`:
      - reads the LangGraph state snapshot,
      - updates `TokenManager` using the messages from state,
      - deletes the thread from the LangGraph checkpointer to free memory.

If the limit (e.g. `TOKEN_LIMIT`) is exceeded, agents return a user-friendly message such as:

> `"Token limit exceeded. Please start a new session or reset your thread."`

### AgentMemoryManager

`AgentMemoryManager` coordinates conversation/memory state.

Internally it uses LangGraph `InMemorySaver` / checkpointer and exposes methods to:

- Bind a RAG graph (`bind_rag_graph(chain)`) so it uses a shared checkpointer.
- Read and write conversation history per `thread_id`.
- Reset or delete a thread’s state when required.

Ownership in practice:

- **RAG**:
  - The RAG graph keeps its internal messages and intermediate steps in the checkpointer keyed by `thread_id`.
  - After each run, `LangGraphTokenMemoryHandler`:
    - reads the snapshot (`chain.get_state(config)`),
    - updates tokens,
    - deletes the thread (`chain.checkpointer.delete_thread(thread_id)`) to avoid unbounded growth in RAM,
    - optionally syncs minimal state back if needed.

- **CLS**:
  - CLS does not maintain a LangGraph state, but still maintains a conversational history:
    - `CloudLoggingHistoryRecorder.record(...)` appends a `HumanMessage` (summary of the search) and an `AIMessage` (tool’s answer) via `AgentMemoryManager`.
  - This allows future calls to see what has been asked and answered before.

---

## Concurrency

### ConcurrencyControl

To prevent race conditions when:

- updating tokens for the same `thread_id`,
- reading/writing memory for the same `thread_id`,

a shared concurrency mechanism is used:

- **`ConcurrencyControl`**:
  - provides keyed locks (typically per `thread_id`),
  - used inside:
    - `TokenUpdateControl` (within `TokenManager`),
    - `AgentMemoryManager`.

### Guarantees

With this design:

- Multiple requests for the same `thread_id` will:
  - not corrupt token counts (atomic / locked updates),
  - not corrupt memory (consistent read/write operations).
- Concurrency logic is centralized and reused by the two most critical stateful subsystems: tokens and memory.

---

This architecture aims to keep responsibilities small and explicit:

- `AgentManager` orchestrates
- `Route` decides control flow
- Agents focus on domain logic (RAG vs Cloud Logging)
- Domain classes (`AgentParams`, `AgentRequest`) model intent and parameters
- Infrastructure components (tokens, memory, concurrency) handle cross-cutting concerns safely.
