SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    auditable_type character varying,
    auditable_id bigint,
    event character varying NOT NULL,
    message text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: code_chunks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.code_chunks (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    code_file_id bigint NOT NULL,
    entity_id bigint,
    chunk_type character varying NOT NULL,
    chunk_text text NOT NULL,
    start_line integer NOT NULL,
    end_line integer NOT NULL,
    token_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    embedding public.vector(1024)
);


--
-- Name: code_chunks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.code_chunks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_chunks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.code_chunks_id_seq OWNED BY public.code_chunks.id;


--
-- Name: code_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.code_files (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    path character varying NOT NULL,
    language character varying NOT NULL,
    content_hash character varying NOT NULL,
    size_bytes integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: code_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.code_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.code_files_id_seq OWNED BY public.code_files.id;


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    user_id bigint,
    title character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- Name: dependency_edges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dependency_edges (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    source_type character varying NOT NULL,
    source_id bigint NOT NULL,
    target_type character varying NOT NULL,
    target_id bigint NOT NULL,
    edge_type character varying NOT NULL,
    confidence numeric(4,2) DEFAULT 0.5 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dependency_edges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dependency_edges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dependency_edges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dependency_edges_id_seq OWNED BY public.dependency_edges.id;


--
-- Name: entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entities (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    code_file_id bigint NOT NULL,
    entity_type character varying NOT NULL,
    name character varying NOT NULL,
    namespace character varying,
    signature character varying,
    metadata_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entities_id_seq OWNED BY public.entities.id;


--
-- Name: entity_relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entity_relationships (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    source_entity_id bigint NOT NULL,
    target_entity_id bigint NOT NULL,
    relationship_type character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: entity_relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entity_relationships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entity_relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entity_relationships_id_seq OWNED BY public.entity_relationships.id;


--
-- Name: impact_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impact_reports (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    query character varying NOT NULL,
    result_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    generated_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: impact_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.impact_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: impact_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.impact_reports_id_seq OWNED BY public.impact_reports.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    role character varying NOT NULL,
    content text NOT NULL,
    cites_json jsonb DEFAULT '[]'::jsonb NOT NULL,
    prompt_tokens integer DEFAULT 0 NOT NULL,
    completion_tokens integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    response_state character varying DEFAULT 'completed'::character varying NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: provider_call_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.provider_call_logs (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    user_id bigint NOT NULL,
    provider character varying NOT NULL,
    operation_type character varying NOT NULL,
    model character varying NOT NULL,
    status character varying NOT NULL,
    endpoint character varying,
    error_message text,
    request_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    response_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    prompt_tokens integer DEFAULT 0 NOT NULL,
    completion_tokens integer DEFAULT 0 NOT NULL,
    total_tokens integer DEFAULT 0 NOT NULL,
    latency_ms integer DEFAULT 0 NOT NULL,
    estimated_cost_usd numeric(12,6),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: provider_call_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.provider_call_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: provider_call_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.provider_call_logs_id_seq OWNED BY public.provider_call_logs.id;


--
-- Name: repositories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repositories (
    id bigint NOT NULL,
    name character varying NOT NULL,
    github_url character varying NOT NULL,
    default_branch character varying NOT NULL,
    tracked_branch character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    visibility character varying DEFAULT 'public'::character varying NOT NULL,
    provider character varying DEFAULT 'github'::character varying NOT NULL,
    last_ingested_at timestamp(6) without time zone,
    last_commit_sha character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    assistant_provider character varying DEFAULT 'local'::character varying NOT NULL,
    assistant_model character varying DEFAULT 'grounded-local'::character varying NOT NULL,
    embedding_provider character varying DEFAULT 'local'::character varying NOT NULL,
    embedding_model character varying DEFAULT 'deterministic-v1'::character varying NOT NULL,
    ollama_base_url character varying DEFAULT 'http://127.0.0.1:11434'::character varying NOT NULL,
    user_id bigint NOT NULL,
    indexed_embedding_provider character varying,
    indexed_embedding_model character varying
);


--
-- Name: repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repositories_id_seq OWNED BY public.repositories.id;


--
-- Name: repository_deletion_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_deletion_logs (
    id bigint NOT NULL,
    deleted_repository_id bigint NOT NULL,
    user_id bigint,
    name character varying NOT NULL,
    github_url character varying NOT NULL,
    provider character varying,
    visibility character varying,
    default_branch character varying,
    tracked_branch character varying,
    status character varying,
    last_commit_sha character varying,
    last_ingested_at timestamp(6) without time zone,
    assistant_provider character varying,
    assistant_model character varying,
    embedding_provider character varying,
    embedding_model character varying,
    deleted_at timestamp(6) without time zone NOT NULL,
    deletion_reason character varying DEFAULT 'user_requested'::character varying NOT NULL,
    summary_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_deletion_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_deletion_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_deletion_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_deletion_logs_id_seq OWNED BY public.repository_deletion_logs.id;


--
-- Name: repository_ingestions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_ingestions (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    branch_name character varying NOT NULL,
    commit_sha character varying,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    started_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    error_message text,
    triggered_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    force_rebuild boolean DEFAULT false NOT NULL
);


--
-- Name: repository_ingestions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_ingestions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_ingestions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_ingestions_id_seq OWNED BY public.repository_ingestions.id;


--
-- Name: repository_routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_routes (
    id bigint NOT NULL,
    repository_id bigint NOT NULL,
    http_method character varying NOT NULL,
    path character varying NOT NULL,
    controller_name character varying,
    action_name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_routes_id_seq OWNED BY public.repository_routes.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying NOT NULL,
    email character varying,
    assistant_provider character varying DEFAULT 'local'::character varying NOT NULL,
    assistant_model character varying DEFAULT 'grounded-local'::character varying NOT NULL,
    embedding_provider character varying DEFAULT 'local'::character varying NOT NULL,
    embedding_model character varying DEFAULT 'deterministic-v1'::character varying NOT NULL,
    ollama_base_url character varying DEFAULT 'http://127.0.0.1:11434'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: code_chunks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_chunks ALTER COLUMN id SET DEFAULT nextval('public.code_chunks_id_seq'::regclass);


--
-- Name: code_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_files ALTER COLUMN id SET DEFAULT nextval('public.code_files_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- Name: dependency_edges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dependency_edges ALTER COLUMN id SET DEFAULT nextval('public.dependency_edges_id_seq'::regclass);


--
-- Name: entities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entities ALTER COLUMN id SET DEFAULT nextval('public.entities_id_seq'::regclass);


--
-- Name: entity_relationships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_relationships ALTER COLUMN id SET DEFAULT nextval('public.entity_relationships_id_seq'::regclass);


--
-- Name: impact_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impact_reports ALTER COLUMN id SET DEFAULT nextval('public.impact_reports_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: provider_call_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provider_call_logs ALTER COLUMN id SET DEFAULT nextval('public.provider_call_logs_id_seq'::regclass);


--
-- Name: repositories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories ALTER COLUMN id SET DEFAULT nextval('public.repositories_id_seq'::regclass);


--
-- Name: repository_deletion_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_deletion_logs ALTER COLUMN id SET DEFAULT nextval('public.repository_deletion_logs_id_seq'::regclass);


--
-- Name: repository_ingestions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_ingestions ALTER COLUMN id SET DEFAULT nextval('public.repository_ingestions_id_seq'::regclass);


--
-- Name: repository_routes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_routes ALTER COLUMN id SET DEFAULT nextval('public.repository_routes_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: code_chunks code_chunks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_chunks
    ADD CONSTRAINT code_chunks_pkey PRIMARY KEY (id);


--
-- Name: code_files code_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_files
    ADD CONSTRAINT code_files_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: dependency_edges dependency_edges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dependency_edges
    ADD CONSTRAINT dependency_edges_pkey PRIMARY KEY (id);


--
-- Name: entities entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (id);


--
-- Name: entity_relationships entity_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_relationships
    ADD CONSTRAINT entity_relationships_pkey PRIMARY KEY (id);


--
-- Name: impact_reports impact_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impact_reports
    ADD CONSTRAINT impact_reports_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: provider_call_logs provider_call_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provider_call_logs
    ADD CONSTRAINT provider_call_logs_pkey PRIMARY KEY (id);


--
-- Name: repositories repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: repository_deletion_logs repository_deletion_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_deletion_logs
    ADD CONSTRAINT repository_deletion_logs_pkey PRIMARY KEY (id);


--
-- Name: repository_ingestions repository_ingestions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_ingestions
    ADD CONSTRAINT repository_ingestions_pkey PRIMARY KEY (id);


--
-- Name: repository_routes repository_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_routes
    ADD CONSTRAINT repository_routes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_code_chunks_file_lines; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_code_chunks_file_lines ON public.code_chunks USING btree (code_file_id, start_line, end_line);


--
-- Name: idx_entity_relationship_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_entity_relationship_uniqueness ON public.entity_relationships USING btree (source_entity_id, target_entity_id, relationship_type);


--
-- Name: idx_on_repository_id_relationship_type_9c3962c979; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_repository_id_relationship_type_9c3962c979 ON public.entity_relationships USING btree (repository_id, relationship_type);


--
-- Name: index_audit_logs_on_auditable_type_and_auditable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_auditable_type_and_auditable_id ON public.audit_logs USING btree (auditable_type, auditable_id);


--
-- Name: index_audit_logs_on_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_event ON public.audit_logs USING btree (event);


--
-- Name: index_audit_logs_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_repository_id ON public.audit_logs USING btree (repository_id);


--
-- Name: index_code_chunks_on_code_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_code_chunks_on_code_file_id ON public.code_chunks USING btree (code_file_id);


--
-- Name: index_code_chunks_on_embedding; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_code_chunks_on_embedding ON public.code_chunks USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: index_code_chunks_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_code_chunks_on_entity_id ON public.code_chunks USING btree (entity_id);


--
-- Name: index_code_chunks_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_code_chunks_on_repository_id ON public.code_chunks USING btree (repository_id);


--
-- Name: index_code_chunks_on_repository_id_and_chunk_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_code_chunks_on_repository_id_and_chunk_type ON public.code_chunks USING btree (repository_id, chunk_type);


--
-- Name: index_code_files_on_language; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_code_files_on_language ON public.code_files USING btree (language);


--
-- Name: index_code_files_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_code_files_on_repository_id ON public.code_files USING btree (repository_id);


--
-- Name: index_code_files_on_repository_id_and_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_code_files_on_repository_id_and_path ON public.code_files USING btree (repository_id, path);


--
-- Name: index_conversations_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_repository_id ON public.conversations USING btree (repository_id);


--
-- Name: index_conversations_on_repository_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_repository_id_and_created_at ON public.conversations USING btree (repository_id, created_at);


--
-- Name: index_conversations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_user_id ON public.conversations USING btree (user_id);


--
-- Name: index_dependency_edges_on_repository_and_edge_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dependency_edges_on_repository_and_edge_type ON public.dependency_edges USING btree (repository_id, edge_type);


--
-- Name: index_dependency_edges_on_repository_and_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dependency_edges_on_repository_and_source ON public.dependency_edges USING btree (repository_id, source_type, source_id);


--
-- Name: index_dependency_edges_on_repository_and_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dependency_edges_on_repository_and_target ON public.dependency_edges USING btree (repository_id, target_type, target_id);


--
-- Name: index_dependency_edges_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dependency_edges_on_repository_id ON public.dependency_edges USING btree (repository_id);


--
-- Name: index_dependency_edges_on_repository_source_target_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dependency_edges_on_repository_source_target_and_type ON public.dependency_edges USING btree (repository_id, source_type, source_id, target_type, target_id, edge_type);


--
-- Name: index_entities_on_code_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_code_file_id ON public.entities USING btree (code_file_id);


--
-- Name: index_entities_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_repository_id ON public.entities USING btree (repository_id);


--
-- Name: index_entities_on_repository_id_and_entity_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_repository_id_and_entity_type ON public.entities USING btree (repository_id, entity_type);


--
-- Name: index_entities_on_repository_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_repository_id_and_name ON public.entities USING btree (repository_id, name);


--
-- Name: index_entity_relationships_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_relationships_on_repository_id ON public.entity_relationships USING btree (repository_id);


--
-- Name: index_entity_relationships_on_source_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_relationships_on_source_entity_id ON public.entity_relationships USING btree (source_entity_id);


--
-- Name: index_entity_relationships_on_target_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_relationships_on_target_entity_id ON public.entity_relationships USING btree (target_entity_id);


--
-- Name: index_impact_reports_on_query; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impact_reports_on_query ON public.impact_reports USING btree (query);


--
-- Name: index_impact_reports_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impact_reports_on_repository_id ON public.impact_reports USING btree (repository_id);


--
-- Name: index_impact_reports_on_repository_id_and_generated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impact_reports_on_repository_id_and_generated_at ON public.impact_reports USING btree (repository_id, generated_at);


--
-- Name: index_messages_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: index_messages_on_conversation_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_conversation_id_and_created_at ON public.messages USING btree (conversation_id, created_at);


--
-- Name: index_messages_on_response_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_response_state ON public.messages USING btree (response_state);


--
-- Name: index_messages_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_role ON public.messages USING btree (role);


--
-- Name: index_provider_call_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_provider_call_logs_on_created_at ON public.provider_call_logs USING btree (created_at);


--
-- Name: index_provider_call_logs_on_provider_operation_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_provider_call_logs_on_provider_operation_status ON public.provider_call_logs USING btree (provider, operation_type, status);


--
-- Name: index_provider_call_logs_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_provider_call_logs_on_repository_id ON public.provider_call_logs USING btree (repository_id);


--
-- Name: index_provider_call_logs_on_repository_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_provider_call_logs_on_repository_id_and_created_at ON public.provider_call_logs USING btree (repository_id, created_at);


--
-- Name: index_provider_call_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_provider_call_logs_on_user_id ON public.provider_call_logs USING btree (user_id);


--
-- Name: index_provider_call_logs_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_provider_call_logs_on_user_id_and_created_at ON public.provider_call_logs USING btree (user_id, created_at);


--
-- Name: index_repositories_on_github_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repositories_on_github_url ON public.repositories USING btree (github_url);


--
-- Name: index_repositories_on_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_provider ON public.repositories USING btree (provider);


--
-- Name: index_repositories_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_status ON public.repositories USING btree (status);


--
-- Name: index_repositories_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_user_id ON public.repositories USING btree (user_id);


--
-- Name: index_repository_deletion_logs_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_deletion_logs_on_deleted_at ON public.repository_deletion_logs USING btree (deleted_at);


--
-- Name: index_repository_deletion_logs_on_deleted_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repository_deletion_logs_on_deleted_repository_id ON public.repository_deletion_logs USING btree (deleted_repository_id);


--
-- Name: index_repository_deletion_logs_on_github_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_deletion_logs_on_github_url ON public.repository_deletion_logs USING btree (github_url);


--
-- Name: index_repository_deletion_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_deletion_logs_on_user_id ON public.repository_deletion_logs USING btree (user_id);


--
-- Name: index_repository_ingestions_on_force_rebuild; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_ingestions_on_force_rebuild ON public.repository_ingestions USING btree (force_rebuild);


--
-- Name: index_repository_ingestions_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_ingestions_on_repository_id ON public.repository_ingestions USING btree (repository_id);


--
-- Name: index_repository_ingestions_on_repository_id_and_branch_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_ingestions_on_repository_id_and_branch_name ON public.repository_ingestions USING btree (repository_id, branch_name);


--
-- Name: index_repository_ingestions_on_repository_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_ingestions_on_repository_id_and_created_at ON public.repository_ingestions USING btree (repository_id, created_at);


--
-- Name: index_repository_ingestions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_ingestions_on_status ON public.repository_ingestions USING btree (status);


--
-- Name: index_repository_ingestions_on_triggered_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_ingestions_on_triggered_by_id ON public.repository_ingestions USING btree (triggered_by_id);


--
-- Name: index_repository_routes_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_routes_on_repository_id ON public.repository_routes USING btree (repository_id);


--
-- Name: index_repository_routes_on_repository_id_and_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_routes_on_repository_id_and_path ON public.repository_routes USING btree (repository_id, path);


--
-- Name: code_chunks fk_rails_16df920657; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_chunks
    ADD CONSTRAINT fk_rails_16df920657 FOREIGN KEY (entity_id) REFERENCES public.entities(id);


--
-- Name: entities fk_rails_2b80909ed0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT fk_rails_2b80909ed0 FOREIGN KEY (code_file_id) REFERENCES public.code_files(id);


--
-- Name: code_chunks fk_rails_3f237dbeb3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_chunks
    ADD CONSTRAINT fk_rails_3f237dbeb3 FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: entity_relationships fk_rails_4038f70d1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_relationships
    ADD CONSTRAINT fk_rails_4038f70d1e FOREIGN KEY (source_entity_id) REFERENCES public.entities(id);


--
-- Name: conversations fk_rails_4e8e28bd69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_rails_4e8e28bd69 FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: audit_logs fk_rails_502c5fef18; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT fk_rails_502c5fef18 FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: dependency_edges fk_rails_596c92edab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dependency_edges
    ADD CONSTRAINT fk_rails_596c92edab FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: repositories fk_rails_5c7f0a15dd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT fk_rails_5c7f0a15dd FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: entities fk_rails_75d1830584; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT fk_rails_75d1830584 FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: messages fk_rails_7f927086d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_7f927086d2 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: code_files fk_rails_8bd7f66a87; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_files
    ADD CONSTRAINT fk_rails_8bd7f66a87 FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: entity_relationships fk_rails_9471f192bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_relationships
    ADD CONSTRAINT fk_rails_9471f192bb FOREIGN KEY (target_entity_id) REFERENCES public.entities(id);


--
-- Name: repository_routes fk_rails_9f13a29d0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_routes
    ADD CONSTRAINT fk_rails_9f13a29d0d FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: provider_call_logs fk_rails_b3c96a3803; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provider_call_logs
    ADD CONSTRAINT fk_rails_b3c96a3803 FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: repository_deletion_logs fk_rails_c43db24b6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_deletion_logs
    ADD CONSTRAINT fk_rails_c43db24b6a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: repository_ingestions fk_rails_d9d13f0d17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_ingestions
    ADD CONSTRAINT fk_rails_d9d13f0d17 FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: provider_call_logs fk_rails_e0db92d9c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provider_call_logs
    ADD CONSTRAINT fk_rails_e0db92d9c8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: entity_relationships fk_rails_ee74df5f9d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_relationships
    ADD CONSTRAINT fk_rails_ee74df5f9d FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: code_chunks fk_rails_f90219b4f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_chunks
    ADD CONSTRAINT fk_rails_f90219b4f1 FOREIGN KEY (code_file_id) REFERENCES public.code_files(id);


--
-- Name: impact_reports fk_rails_fc9da5fdab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impact_reports
    ADD CONSTRAINT fk_rails_fc9da5fdab FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260630153000'),
('20260630120000'),
('20260626231000'),
('20260626224137'),
('20260626113000'),
('20260626101500'),
('20260626090000'),
('20260626073000'),
('20260625152000'),
('20260625140000'),
('20260625123100'),
('20260625123000'),
('20260625110000'),
('20260622133000'),
('20260622123000'),
('20260622113200'),
('20260622113100'),
('20260622113000'),
('20260622100000'),
('20260622072600'),
('20260622072500');

