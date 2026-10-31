--
-- PostgreSQL database dump
--

-- Dumped from database version 17.9 (Debian 17.9-1.pgdg13+1)
-- Dumped by pg_dump version 17.5

-- Started on 2026-09-25 17:14:09 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 18507)
-- Name: public; Type: SCHEMA; Schema: -; Owner: demo_app
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO demo_app;

--
-- TOC entry 923 (class 1247 OID 18644)
-- Name: access_role; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.access_role AS ENUM (
    'Admin',
    'User',
    'Viewer',
    'Framework Owner'
);


ALTER TYPE public.access_role OWNER TO demo_app;

--
-- TOC entry 890 (class 1247 OID 18556)
-- Name: access_status; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.access_status AS ENUM (
    'Approved',
    'Pending'
);


ALTER TYPE public.access_status OWNER TO demo_app;

--
-- TOC entry 875 (class 1247 OID 18509)
-- Name: assessment_type; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.assessment_type AS ENUM (
    'Self assessment',
    'Peer review',
    'Focused peer review'
);


ALTER TYPE public.assessment_type OWNER TO demo_app;

--
-- TOC entry 920 (class 1247 OID 18636)
-- Name: audit_action; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.audit_action AS ENUM (
    'create',
    'update',
    'delete'
);


ALTER TYPE public.audit_action OWNER TO demo_app;

--
-- TOC entry 878 (class 1247 OID 18516)
-- Name: comment_kind; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.comment_kind AS ENUM (
    'comment',
    'recommendation'
);


ALTER TYPE public.comment_kind OWNER TO demo_app;

--
-- TOC entry 902 (class 1247 OID 18592)
-- Name: favorite_score_type; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.favorite_score_type AS ENUM (
    'Peer'
);


ALTER TYPE public.favorite_score_type OWNER TO demo_app;

--
-- TOC entry 908 (class 1247 OID 18602)
-- Name: job_status; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.job_status AS ENUM (
    'queued',
    'running',
    'done',
    'failed'
);


ALTER TYPE public.job_status OWNER TO demo_app;

--
-- TOC entry 905 (class 1247 OID 18596)
-- Name: job_type; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.job_type AS ENUM (
    'question_generation',
    'excel_export'
);


ALTER TYPE public.job_type OWNER TO demo_app;

--
-- TOC entry 911 (class 1247 OID 18612)
-- Name: notification_type; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.notification_type AS ENUM (
    'access_granted',
    'ticket_created',
    'ticket_update',
    'ticket_status_changed'
);


ALTER TYPE public.notification_type OWNER TO demo_app;

--
-- TOC entry 914 (class 1247 OID 18622)
-- Name: question_level; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.question_level AS ENUM (
    'plant',
    'entity',
    'both'
);


ALTER TYPE public.question_level OWNER TO demo_app;

--
-- TOC entry 881 (class 1247 OID 18522)
-- Name: recommendation_status; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.recommendation_status AS ENUM (
    'Open',
    'In Progress',
    'Done',
    'N/A'
);


ALTER TYPE public.recommendation_status OWNER TO demo_app;

--
-- TOC entry 884 (class 1247 OID 18532)
-- Name: region; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.region AS ENUM (
    'AMEA',
    'Europe',
    'LATAM',
    'NORAM'
);


ALTER TYPE public.region OWNER TO demo_app;

--
-- TOC entry 917 (class 1247 OID 18630)
-- Name: scope_level; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.scope_level AS ENUM (
    'plant',
    'entity'
);


ALTER TYPE public.scope_level OWNER TO demo_app;

--
-- TOC entry 887 (class 1247 OID 18542)
-- Name: score; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.score AS ENUM (
    '0',
    '1',
    '2',
    '3',
    '4',
    'N/A'
);


ALTER TYPE public.score OWNER TO demo_app;

--
-- TOC entry 896 (class 1247 OID 18572)
-- Name: ticket_impact; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.ticket_impact AS ENUM (
    'Affecting all operations',
    'Partially affecting operations',
    'Not affecting operations'
);


ALTER TYPE public.ticket_impact OWNER TO demo_app;

--
-- TOC entry 893 (class 1247 OID 18562)
-- Name: ticket_request_type; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.ticket_request_type AS ENUM (
    'Bug',
    'Feedback',
    'Access',
    'Question'
);


ALTER TYPE public.ticket_request_type OWNER TO demo_app;

--
-- TOC entry 899 (class 1247 OID 18580)
-- Name: ticket_status; Type: TYPE; Schema: public; Owner: demo_app
--

CREATE TYPE public.ticket_status AS ENUM (
    'Open',
    'In progress',
    'Blocked',
    'Waiting for update',
    'Resolved'
);


ALTER TYPE public.ticket_status OWNER TO demo_app;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 217 (class 1259 OID 18653)
-- Name: access_plants; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.access_plants (
    access_id uuid NOT NULL,
    plant_id character varying(100) NOT NULL
);


ALTER TABLE public.access_plants OWNER TO demo_app;

--
-- TOC entry 218 (class 1259 OID 18660)
-- Name: accesses; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.accesses (
    id uuid NOT NULL,
    okta_sub character varying(255) NOT NULL,
    mail character varying(255) NOT NULL,
    display_name character varying(255) NOT NULL,
    role public.access_role NOT NULL,
    status public.access_status NOT NULL,
    country character varying(100)
);


ALTER TABLE public.accesses OWNER TO demo_app;

--
-- TOC entry 219 (class 1259 OID 18675)
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO demo_app;

--
-- TOC entry 220 (class 1259 OID 18682)
-- Name: answer_comments; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.answer_comments (
    id uuid NOT NULL,
    answer_id uuid NOT NULL,
    author_id uuid,
    author_name character varying(255) NOT NULL,
    text text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    kind public.comment_kind DEFAULT 'comment'::public.comment_kind NOT NULL,
    owner_id uuid,
    owner_name character varying(255),
    target_date date,
    status public.recommendation_status
);


ALTER TABLE public.answer_comments OWNER TO demo_app;

--
-- TOC entry 221 (class 1259 OID 18699)
-- Name: answers; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.answers (
    id uuid NOT NULL,
    assessment_id uuid NOT NULL,
    question_id uuid NOT NULL,
    element integer NOT NULL,
    is_scorable boolean NOT NULL,
    score public.score,
    score_owner uuid,
    comment text,
    comment_owner uuid,
    comment_date timestamp with time zone,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    question_number character varying(20) DEFAULT ''::character varying NOT NULL,
    question_title character varying(500) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.answers OWNER TO demo_app;

--
-- TOC entry 222 (class 1259 OID 18730)
-- Name: assessment_review_owners; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.assessment_review_owners (
    assessment_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.assessment_review_owners OWNER TO demo_app;

--
-- TOC entry 223 (class 1259 OID 18737)
-- Name: assessment_selected_elements; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.assessment_selected_elements (
    assessment_id uuid NOT NULL,
    element_number integer NOT NULL
);


ALTER TABLE public.assessment_selected_elements OWNER TO demo_app;

--
-- TOC entry 224 (class 1259 OID 18744)
-- Name: assessment_technologies; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.assessment_technologies (
    assessment_id uuid NOT NULL,
    technology character varying(100) NOT NULL
);


ALTER TABLE public.assessment_technologies OWNER TO demo_app;

--
-- TOC entry 225 (class 1259 OID 18751)
-- Name: assessment_type_elements; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.assessment_type_elements (
    assessment_type_id uuid NOT NULL,
    element_number integer NOT NULL,
    "position" integer
);


ALTER TABLE public.assessment_type_elements OWNER TO demo_app;

--
-- TOC entry 226 (class 1259 OID 18758)
-- Name: assessment_types; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.assessment_types (
    id uuid NOT NULL,
    code public.assessment_type,
    name character varying(255) NOT NULL,
    slug character varying(100) NOT NULL,
    owner_id uuid,
    is_system boolean DEFAULT false NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    framework_id uuid
);


ALTER TABLE public.assessment_types OWNER TO demo_app;

--
-- TOC entry 227 (class 1259 OID 18775)
-- Name: assessment_viewers; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.assessment_viewers (
    assessment_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.assessment_viewers OWNER TO demo_app;

--
-- TOC entry 228 (class 1259 OID 18782)
-- Name: assessments; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.assessments (
    id uuid NOT NULL,
    plant_id character varying(100),
    plant_name character varying(255),
    region public.region,
    country character varying(100),
    type public.assessment_type NOT NULL,
    custom boolean DEFAULT false NOT NULL,
    related_assessment_id uuid,
    planned_start date NOT NULL,
    planned_end date NOT NULL,
    actual_start date,
    actual_end date,
    comments text,
    closed boolean DEFAULT false NOT NULL,
    right_number_of_questions integer DEFAULT 0 NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    assessment_type_id uuid NOT NULL,
    scope_level public.scope_level DEFAULT 'plant'::public.scope_level NOT NULL,
    entity_id uuid,
    old_assessment_id character varying(64)
);


ALTER TABLE public.assessments OWNER TO demo_app;

--
-- TOC entry 229 (class 1259 OID 18809)
-- Name: audit_events; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.audit_events (
    id uuid NOT NULL,
    action public.audit_action NOT NULL,
    entity character varying(100) NOT NULL,
    entity_id character varying(100),
    actor_id uuid,
    request_id character varying(100),
    changes json,
    context json,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_events OWNER TO demo_app;

--
-- TOC entry 230 (class 1259 OID 18827)
-- Name: document_links; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.document_links (
    id uuid NOT NULL,
    document_id uuid NOT NULL,
    assessment_id uuid,
    answer_id uuid
);


ALTER TABLE public.document_links OWNER TO demo_app;

--
-- TOC entry 231 (class 1259 OID 18836)
-- Name: documents; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.documents (
    id uuid NOT NULL,
    name character varying(500) NOT NULL,
    url character varying(2048) NOT NULL,
    thumbnail character varying(2048),
    element integer,
    plant_id character varying(100),
    assessment_type public.assessment_type,
    created_by uuid NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    peer_score integer DEFAULT 0 NOT NULL,
    storage_path character varying(2048)
);


ALTER TABLE public.documents OWNER TO demo_app;

--
-- TOC entry 232 (class 1259 OID 18851)
-- Name: element_owners; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.element_owners (
    id uuid NOT NULL,
    assessment_id uuid NOT NULL,
    element integer NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.element_owners OWNER TO demo_app;

--
-- TOC entry 233 (class 1259 OID 18862)
-- Name: elements_element_number_seq; Type: SEQUENCE; Schema: public; Owner: demo_app
--

CREATE SEQUENCE public.elements_element_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.elements_element_number_seq OWNER TO demo_app;

--
-- TOC entry 234 (class 1259 OID 18863)
-- Name: elements; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.elements (
    element_number integer DEFAULT nextval('public.elements_element_number_seq'::regclass) NOT NULL,
    element_title character varying(255) NOT NULL
);


ALTER TABLE public.elements OWNER TO demo_app;

--
-- TOC entry 235 (class 1259 OID 18871)
-- Name: entities; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.entities (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    region public.region NOT NULL,
    country character varying(100) NOT NULL,
    review_owner_id uuid
);


ALTER TABLE public.entities OWNER TO demo_app;

--
-- TOC entry 236 (class 1259 OID 18884)
-- Name: favorite_documents; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.favorite_documents (
    id uuid NOT NULL,
    document_id uuid NOT NULL,
    user_id uuid NOT NULL,
    element integer,
    score_type public.favorite_score_type NOT NULL
);


ALTER TABLE public.favorite_documents OWNER TO demo_app;

--
-- TOC entry 237 (class 1259 OID 18893)
-- Name: frameworks; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.frameworks (
    id uuid NOT NULL,
    label character varying(100) NOT NULL,
    owner_id uuid,
    is_system boolean DEFAULT false NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.frameworks OWNER TO demo_app;

--
-- TOC entry 238 (class 1259 OID 18908)
-- Name: jobs; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.jobs (
    id uuid NOT NULL,
    job_type public.job_type NOT NULL,
    status public.job_status NOT NULL,
    progress integer DEFAULT 0 NOT NULL,
    assessment_id uuid,
    result_ref character varying(2048),
    error text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.jobs OWNER TO demo_app;

--
-- TOC entry 239 (class 1259 OID 18924)
-- Name: notifications; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.notifications (
    id uuid NOT NULL,
    dedup_key character varying(255) NOT NULL,
    type public.notification_type NOT NULL,
    recipient_id uuid NOT NULL,
    subject character varying(500) NOT NULL,
    body text NOT NULL,
    ticket_id uuid,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notifications OWNER TO demo_app;

--
-- TOC entry 240 (class 1259 OID 18940)
-- Name: question_frameworks; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.question_frameworks (
    question_id uuid NOT NULL,
    framework character varying(100) NOT NULL
);


ALTER TABLE public.question_frameworks OWNER TO demo_app;

--
-- TOC entry 241 (class 1259 OID 18947)
-- Name: question_technologies; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.question_technologies (
    question_id uuid NOT NULL,
    technology character varying(100) NOT NULL
);


ALTER TABLE public.question_technologies OWNER TO demo_app;

--
-- TOC entry 242 (class 1259 OID 18954)
-- Name: questions; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.questions (
    id uuid NOT NULL,
    element_number integer NOT NULL,
    sub_element integer,
    sub_sub_element integer,
    question_number character varying(20) NOT NULL,
    is_scorable boolean NOT NULL,
    title_question character varying(500) NOT NULL,
    description text,
    definition text,
    opbars_code character varying(255),
    opbars_title text,
    weight numeric(5,2),
    income text,
    level public.question_level DEFAULT 'both'::public.question_level NOT NULL,
    version numeric(3,1)
);


ALTER TABLE public.questions OWNER TO demo_app;

--
-- TOC entry 243 (class 1259 OID 18968)
-- Name: site_technologies; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.site_technologies (
    site_id uuid NOT NULL,
    technology character varying(100) NOT NULL
);


ALTER TABLE public.site_technologies OWNER TO demo_app;

--
-- TOC entry 244 (class 1259 OID 18975)
-- Name: sites; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.sites (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    region public.region NOT NULL,
    country character varying(100) NOT NULL,
    entity_id uuid,
    review_owner_id uuid
);


ALTER TABLE public.sites OWNER TO demo_app;

--
-- TOC entry 245 (class 1259 OID 18990)
-- Name: ticket_updates; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.ticket_updates (
    id uuid NOT NULL,
    ticket_id uuid NOT NULL,
    author uuid NOT NULL,
    content text NOT NULL,
    internal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.ticket_updates OWNER TO demo_app;

--
-- TOC entry 246 (class 1259 OID 19005)
-- Name: tickets; Type: TABLE; Schema: public; Owner: demo_app
--

CREATE TABLE public.tickets (
    id uuid NOT NULL,
    app character varying(20) DEFAULT 'OEV3'::character varying NOT NULL,
    request_type public.ticket_request_type NOT NULL,
    impact public.ticket_impact NOT NULL,
    description text NOT NULL,
    screenshot_url character varying(2048),
    status public.ticket_status NOT NULL,
    created_by uuid NOT NULL,
    assigned_to uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tickets OWNER TO demo_app;

--
-- TOC entry 3474 (class 2606 OID 18679)
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- TOC entry 3468 (class 2606 OID 18657)
-- Name: access_plants pk_access_plants; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.access_plants
    ADD CONSTRAINT pk_access_plants PRIMARY KEY (access_id, plant_id);


--
-- TOC entry 3471 (class 2606 OID 18666)
-- Name: accesses pk_accesses; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.accesses
    ADD CONSTRAINT pk_accesses PRIMARY KEY (id);


--
-- TOC entry 3478 (class 2606 OID 18690)
-- Name: answer_comments pk_answer_comments; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.answer_comments
    ADD CONSTRAINT pk_answer_comments PRIMARY KEY (id);


--
-- TOC entry 3483 (class 2606 OID 18708)
-- Name: answers pk_answers; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT pk_answers PRIMARY KEY (id);


--
-- TOC entry 3486 (class 2606 OID 18734)
-- Name: assessment_review_owners pk_assessment_review_owners; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_review_owners
    ADD CONSTRAINT pk_assessment_review_owners PRIMARY KEY (assessment_id, user_id);


--
-- TOC entry 3488 (class 2606 OID 18741)
-- Name: assessment_selected_elements pk_assessment_selected_elements; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_selected_elements
    ADD CONSTRAINT pk_assessment_selected_elements PRIMARY KEY (assessment_id, element_number);


--
-- TOC entry 3490 (class 2606 OID 18748)
-- Name: assessment_technologies pk_assessment_technologies; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_technologies
    ADD CONSTRAINT pk_assessment_technologies PRIMARY KEY (assessment_id, technology);


--
-- TOC entry 3500 (class 2606 OID 18779)
-- Name: assessment_viewers pk_assessment_viewers; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_viewers
    ADD CONSTRAINT pk_assessment_viewers PRIMARY KEY (assessment_id, user_id);


--
-- TOC entry 3507 (class 2606 OID 18794)
-- Name: assessments pk_assessments; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT pk_assessments PRIMARY KEY (id);


--
-- TOC entry 3512 (class 2606 OID 18816)
-- Name: audit_events pk_audit_events; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT pk_audit_events PRIMARY KEY (id);


--
-- TOC entry 3515 (class 2606 OID 18831)
-- Name: document_links pk_document_links; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.document_links
    ADD CONSTRAINT pk_document_links PRIMARY KEY (id);


--
-- TOC entry 3518 (class 2606 OID 18844)
-- Name: documents pk_documents; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT pk_documents PRIMARY KEY (id);


--
-- TOC entry 3521 (class 2606 OID 18855)
-- Name: element_owners pk_element_owners; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.element_owners
    ADD CONSTRAINT pk_element_owners PRIMARY KEY (id);


--
-- TOC entry 3524 (class 2606 OID 18868)
-- Name: elements pk_elements; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.elements
    ADD CONSTRAINT pk_elements PRIMARY KEY (element_number);


--
-- TOC entry 3528 (class 2606 OID 18875)
-- Name: entities pk_entities; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT pk_entities PRIMARY KEY (id);


--
-- TOC entry 3531 (class 2606 OID 18888)
-- Name: favorite_documents pk_favorite_documents; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.favorite_documents
    ADD CONSTRAINT pk_favorite_documents PRIMARY KEY (id);


--
-- TOC entry 3492 (class 2606 OID 18755)
-- Name: assessment_type_elements pk_framework_elements; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_type_elements
    ADD CONSTRAINT pk_framework_elements PRIMARY KEY (assessment_type_id, element_number);


--
-- TOC entry 3496 (class 2606 OID 18764)
-- Name: assessment_types pk_frameworks; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_types
    ADD CONSTRAINT pk_frameworks PRIMARY KEY (id);


--
-- TOC entry 3539 (class 2606 OID 18917)
-- Name: jobs pk_jobs; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT pk_jobs PRIMARY KEY (id);


--
-- TOC entry 3542 (class 2606 OID 18931)
-- Name: notifications pk_notifications; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT pk_notifications PRIMARY KEY (id);


--
-- TOC entry 3545 (class 2606 OID 18944)
-- Name: question_frameworks pk_question_question_types; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.question_frameworks
    ADD CONSTRAINT pk_question_question_types PRIMARY KEY (question_id, framework);


--
-- TOC entry 3547 (class 2606 OID 18951)
-- Name: question_technologies pk_question_technologies; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.question_technologies
    ADD CONSTRAINT pk_question_technologies PRIMARY KEY (question_id, technology);


--
-- TOC entry 3535 (class 2606 OID 18901)
-- Name: frameworks pk_question_types; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.frameworks
    ADD CONSTRAINT pk_question_types PRIMARY KEY (id);


--
-- TOC entry 3550 (class 2606 OID 18961)
-- Name: questions pk_questions; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT pk_questions PRIMARY KEY (id);


--
-- TOC entry 3552 (class 2606 OID 18972)
-- Name: site_technologies pk_site_technologies; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.site_technologies
    ADD CONSTRAINT pk_site_technologies PRIMARY KEY (site_id, technology);


--
-- TOC entry 3557 (class 2606 OID 18979)
-- Name: sites pk_sites; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT pk_sites PRIMARY KEY (id);


--
-- TOC entry 3561 (class 2606 OID 18998)
-- Name: ticket_updates pk_ticket_updates; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.ticket_updates
    ADD CONSTRAINT pk_ticket_updates PRIMARY KEY (id);


--
-- TOC entry 3565 (class 2606 OID 19013)
-- Name: tickets pk_tickets; Type: CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT pk_tickets PRIMARY KEY (id);


--
-- TOC entry 3469 (class 1259 OID 18668)
-- Name: ix_accesses_okta_sub; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_accesses_okta_sub ON public.accesses USING btree (okta_sub);


--
-- TOC entry 3475 (class 1259 OID 18691)
-- Name: ix_answer_comments_answer_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_answer_comments_answer_id ON public.answer_comments USING btree (answer_id);


--
-- TOC entry 3476 (class 1259 OID 18692)
-- Name: ix_answer_comments_owner_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_answer_comments_owner_id ON public.answer_comments USING btree (owner_id);


--
-- TOC entry 3479 (class 1259 OID 18710)
-- Name: ix_answers_assessment_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_answers_assessment_id ON public.answers USING btree (assessment_id);


--
-- TOC entry 3480 (class 1259 OID 18712)
-- Name: ix_answers_element; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_answers_element ON public.answers USING btree (element);


--
-- TOC entry 3481 (class 1259 OID 18711)
-- Name: ix_answers_question_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_answers_question_id ON public.answers USING btree (question_id);


--
-- TOC entry 3493 (class 1259 OID 18767)
-- Name: ix_assessment_types_framework_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_assessment_types_framework_id ON public.assessment_types USING btree (framework_id);


--
-- TOC entry 3494 (class 1259 OID 18766)
-- Name: ix_assessment_types_owner_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_assessment_types_owner_id ON public.assessment_types USING btree (owner_id);


--
-- TOC entry 3501 (class 1259 OID 18797)
-- Name: ix_assessments_assessment_type_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_assessments_assessment_type_id ON public.assessments USING btree (assessment_type_id);


--
-- TOC entry 3502 (class 1259 OID 18796)
-- Name: ix_assessments_closed; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_assessments_closed ON public.assessments USING btree (closed);


--
-- TOC entry 3503 (class 1259 OID 18798)
-- Name: ix_assessments_entity_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_assessments_entity_id ON public.assessments USING btree (entity_id);


--
-- TOC entry 3504 (class 1259 OID 18795)
-- Name: ix_assessments_plant_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_assessments_plant_id ON public.assessments USING btree (plant_id);


--
-- TOC entry 3505 (class 1259 OID 18799)
-- Name: ix_assessments_type; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_assessments_type ON public.assessments USING btree (type);


--
-- TOC entry 3508 (class 1259 OID 18818)
-- Name: ix_audit_events_actor_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_audit_events_actor_id ON public.audit_events USING btree (actor_id);


--
-- TOC entry 3509 (class 1259 OID 18819)
-- Name: ix_audit_events_created_at; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_audit_events_created_at ON public.audit_events USING btree (created_at);


--
-- TOC entry 3510 (class 1259 OID 18817)
-- Name: ix_audit_events_entity; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_audit_events_entity ON public.audit_events USING btree (entity, entity_id);


--
-- TOC entry 3513 (class 1259 OID 18832)
-- Name: ix_document_links_document_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_document_links_document_id ON public.document_links USING btree (document_id);


--
-- TOC entry 3516 (class 1259 OID 18845)
-- Name: ix_documents_element; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_documents_element ON public.documents USING btree (element);


--
-- TOC entry 3519 (class 1259 OID 18857)
-- Name: ix_element_owners_assessment_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_element_owners_assessment_id ON public.element_owners USING btree (assessment_id);


--
-- TOC entry 3525 (class 1259 OID 18877)
-- Name: ix_entities_name; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_entities_name ON public.entities USING btree (name);


--
-- TOC entry 3526 (class 1259 OID 18878)
-- Name: ix_entities_review_owner_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_entities_review_owner_id ON public.entities USING btree (review_owner_id);


--
-- TOC entry 3533 (class 1259 OID 18903)
-- Name: ix_frameworks_label; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX ix_frameworks_label ON public.frameworks USING btree (label);


--
-- TOC entry 3537 (class 1259 OID 18918)
-- Name: ix_jobs_assessment_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_jobs_assessment_id ON public.jobs USING btree (assessment_id);


--
-- TOC entry 3540 (class 1259 OID 18933)
-- Name: ix_notifications_recipient_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_notifications_recipient_id ON public.notifications USING btree (recipient_id);


--
-- TOC entry 3548 (class 1259 OID 18962)
-- Name: ix_questions_element_number; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_questions_element_number ON public.questions USING btree (element_number);


--
-- TOC entry 3553 (class 1259 OID 18982)
-- Name: ix_sites_entity_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_sites_entity_id ON public.sites USING btree (entity_id);


--
-- TOC entry 3554 (class 1259 OID 18981)
-- Name: ix_sites_name; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_sites_name ON public.sites USING btree (name);


--
-- TOC entry 3555 (class 1259 OID 18983)
-- Name: ix_sites_review_owner_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_sites_review_owner_id ON public.sites USING btree (review_owner_id);


--
-- TOC entry 3559 (class 1259 OID 18999)
-- Name: ix_ticket_updates_ticket_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_ticket_updates_ticket_id ON public.ticket_updates USING btree (ticket_id);


--
-- TOC entry 3562 (class 1259 OID 19014)
-- Name: ix_tickets_created_by; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_tickets_created_by ON public.tickets USING btree (created_by);


--
-- TOC entry 3563 (class 1259 OID 19015)
-- Name: ix_tickets_status; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE INDEX ix_tickets_status ON public.tickets USING btree (status);


--
-- TOC entry 3472 (class 1259 OID 18667)
-- Name: uq_accesses_okta_sub; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_accesses_okta_sub ON public.accesses USING btree (okta_sub);


--
-- TOC entry 3484 (class 1259 OID 18709)
-- Name: uq_answers_assessment_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_answers_assessment_id ON public.answers USING btree (assessment_id, question_id);


--
-- TOC entry 3497 (class 1259 OID 18768)
-- Name: uq_assessment_types_framework_code; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_assessment_types_framework_code ON public.assessment_types USING btree (framework_id, code);


--
-- TOC entry 3498 (class 1259 OID 18765)
-- Name: uq_assessment_types_slug; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_assessment_types_slug ON public.assessment_types USING btree (slug);


--
-- TOC entry 3522 (class 1259 OID 18856)
-- Name: uq_element_owners_assessment_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_element_owners_assessment_id ON public.element_owners USING btree (assessment_id, element, user_id);


--
-- TOC entry 3529 (class 1259 OID 18876)
-- Name: uq_entities_name; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_entities_name ON public.entities USING btree (name);


--
-- TOC entry 3532 (class 1259 OID 18889)
-- Name: uq_favorite_documents_document_id; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_favorite_documents_document_id ON public.favorite_documents USING btree (document_id, user_id);


--
-- TOC entry 3536 (class 1259 OID 18902)
-- Name: uq_frameworks_label; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_frameworks_label ON public.frameworks USING btree (label);


--
-- TOC entry 3543 (class 1259 OID 18932)
-- Name: uq_notifications_dedup_key; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_notifications_dedup_key ON public.notifications USING btree (dedup_key);


--
-- TOC entry 3558 (class 1259 OID 18980)
-- Name: uq_sites_name; Type: INDEX; Schema: public; Owner: demo_app
--

CREATE UNIQUE INDEX uq_sites_name ON public.sites USING btree (name);


--
-- TOC entry 3566 (class 2606 OID 19022)
-- Name: access_plants fk_access_plants_access_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.access_plants
    ADD CONSTRAINT fk_access_plants_access_id_accesses FOREIGN KEY (access_id) REFERENCES public.accesses(id) ON DELETE CASCADE;


--
-- TOC entry 3567 (class 2606 OID 19027)
-- Name: answer_comments fk_answer_comments_answer_id_answers; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.answer_comments
    ADD CONSTRAINT fk_answer_comments_answer_id_answers FOREIGN KEY (answer_id) REFERENCES public.answers(id) ON DELETE CASCADE;


--
-- TOC entry 3568 (class 2606 OID 19032)
-- Name: answer_comments fk_answer_comments_author_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.answer_comments
    ADD CONSTRAINT fk_answer_comments_author_id_accesses FOREIGN KEY (author_id) REFERENCES public.accesses(id) ON DELETE SET NULL;


--
-- TOC entry 3569 (class 2606 OID 19037)
-- Name: answer_comments fk_answer_comments_owner_id; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.answer_comments
    ADD CONSTRAINT fk_answer_comments_owner_id FOREIGN KEY (owner_id) REFERENCES public.accesses(id) ON DELETE SET NULL;


--
-- TOC entry 3570 (class 2606 OID 19042)
-- Name: answers fk_answers_assessment_id_assessments; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT fk_answers_assessment_id_assessments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- TOC entry 3571 (class 2606 OID 19047)
-- Name: answers fk_answers_comment_owner_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT fk_answers_comment_owner_accesses FOREIGN KEY (comment_owner) REFERENCES public.accesses(id) ON DELETE SET NULL;


--
-- TOC entry 3572 (class 2606 OID 19052)
-- Name: answers fk_answers_question_id_questions; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT fk_answers_question_id_questions FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE;


--
-- TOC entry 3573 (class 2606 OID 19057)
-- Name: answers fk_answers_score_owner_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT fk_answers_score_owner_accesses FOREIGN KEY (score_owner) REFERENCES public.accesses(id) ON DELETE SET NULL;


--
-- TOC entry 3574 (class 2606 OID 19062)
-- Name: assessment_review_owners fk_assessment_review_owners_assessment_id_assessments; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_review_owners
    ADD CONSTRAINT fk_assessment_review_owners_assessment_id_assessments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- TOC entry 3575 (class 2606 OID 19067)
-- Name: assessment_review_owners fk_assessment_review_owners_user_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_review_owners
    ADD CONSTRAINT fk_assessment_review_owners_user_id_accesses FOREIGN KEY (user_id) REFERENCES public.accesses(id) ON DELETE CASCADE;


--
-- TOC entry 3576 (class 2606 OID 19072)
-- Name: assessment_selected_elements fk_assessment_selected_elements_assessment_id_assessments; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_selected_elements
    ADD CONSTRAINT fk_assessment_selected_elements_assessment_id_assessments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- TOC entry 3577 (class 2606 OID 19077)
-- Name: assessment_technologies fk_assessment_technologies_assessment_id_assessments; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_technologies
    ADD CONSTRAINT fk_assessment_technologies_assessment_id_assessments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- TOC entry 3580 (class 2606 OID 19092)
-- Name: assessment_types fk_assessment_types_framework_id; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_types
    ADD CONSTRAINT fk_assessment_types_framework_id FOREIGN KEY (framework_id) REFERENCES public.frameworks(id) ON DELETE RESTRICT;


--
-- TOC entry 3582 (class 2606 OID 19102)
-- Name: assessment_viewers fk_assessment_viewers_assessment_id_assessments; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_viewers
    ADD CONSTRAINT fk_assessment_viewers_assessment_id_assessments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- TOC entry 3583 (class 2606 OID 19107)
-- Name: assessment_viewers fk_assessment_viewers_user_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_viewers
    ADD CONSTRAINT fk_assessment_viewers_user_id_accesses FOREIGN KEY (user_id) REFERENCES public.accesses(id) ON DELETE CASCADE;


--
-- TOC entry 3584 (class 2606 OID 19112)
-- Name: assessments fk_assessments_assessment_type_id; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT fk_assessments_assessment_type_id FOREIGN KEY (assessment_type_id) REFERENCES public.assessment_types(id);


--
-- TOC entry 3585 (class 2606 OID 19117)
-- Name: assessments fk_assessments_created_by_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT fk_assessments_created_by_accesses FOREIGN KEY (created_by) REFERENCES public.accesses(id);


--
-- TOC entry 3586 (class 2606 OID 19122)
-- Name: assessments fk_assessments_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT fk_assessments_entity_id FOREIGN KEY (entity_id) REFERENCES public.entities(id) ON DELETE SET NULL;


--
-- TOC entry 3587 (class 2606 OID 19127)
-- Name: assessments fk_assessments_related_assessment_id_assessments; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT fk_assessments_related_assessment_id_assessments FOREIGN KEY (related_assessment_id) REFERENCES public.assessments(id) ON DELETE SET NULL;


--
-- TOC entry 3588 (class 2606 OID 19132)
-- Name: document_links fk_document_links_answer_id_answers; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.document_links
    ADD CONSTRAINT fk_document_links_answer_id_answers FOREIGN KEY (answer_id) REFERENCES public.answers(id) ON DELETE CASCADE;


--
-- TOC entry 3589 (class 2606 OID 19137)
-- Name: document_links fk_document_links_assessment_id_assessments; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.document_links
    ADD CONSTRAINT fk_document_links_assessment_id_assessments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- TOC entry 3590 (class 2606 OID 19142)
-- Name: document_links fk_document_links_document_id_documents; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.document_links
    ADD CONSTRAINT fk_document_links_document_id_documents FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE CASCADE;


--
-- TOC entry 3591 (class 2606 OID 19147)
-- Name: documents fk_documents_created_by_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT fk_documents_created_by_accesses FOREIGN KEY (created_by) REFERENCES public.accesses(id);


--
-- TOC entry 3592 (class 2606 OID 19152)
-- Name: element_owners fk_element_owners_assessment_id_assessments; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.element_owners
    ADD CONSTRAINT fk_element_owners_assessment_id_assessments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- TOC entry 3593 (class 2606 OID 19157)
-- Name: element_owners fk_element_owners_user_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.element_owners
    ADD CONSTRAINT fk_element_owners_user_id_accesses FOREIGN KEY (user_id) REFERENCES public.accesses(id) ON DELETE CASCADE;


--
-- TOC entry 3594 (class 2606 OID 19162)
-- Name: entities fk_entities_review_owner_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT fk_entities_review_owner_id_accesses FOREIGN KEY (review_owner_id) REFERENCES public.accesses(id) ON DELETE SET NULL;


--
-- TOC entry 3595 (class 2606 OID 19167)
-- Name: favorite_documents fk_favorite_documents_document_id_documents; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.favorite_documents
    ADD CONSTRAINT fk_favorite_documents_document_id_documents FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE CASCADE;


--
-- TOC entry 3596 (class 2606 OID 19172)
-- Name: favorite_documents fk_favorite_documents_user_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.favorite_documents
    ADD CONSTRAINT fk_favorite_documents_user_id_accesses FOREIGN KEY (user_id) REFERENCES public.accesses(id) ON DELETE CASCADE;


--
-- TOC entry 3578 (class 2606 OID 19082)
-- Name: assessment_type_elements fk_framework_elements_element_number_elements; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_type_elements
    ADD CONSTRAINT fk_framework_elements_element_number_elements FOREIGN KEY (element_number) REFERENCES public.elements(element_number) ON DELETE CASCADE;


--
-- TOC entry 3579 (class 2606 OID 19087)
-- Name: assessment_type_elements fk_framework_elements_framework_id_frameworks; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_type_elements
    ADD CONSTRAINT fk_framework_elements_framework_id_frameworks FOREIGN KEY (assessment_type_id) REFERENCES public.assessment_types(id) ON DELETE CASCADE;


--
-- TOC entry 3581 (class 2606 OID 19097)
-- Name: assessment_types fk_frameworks_owner_id; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.assessment_types
    ADD CONSTRAINT fk_frameworks_owner_id FOREIGN KEY (owner_id) REFERENCES public.accesses(id) ON DELETE SET NULL;


--
-- TOC entry 3598 (class 2606 OID 19182)
-- Name: notifications fk_notifications_recipient_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_recipient_id_accesses FOREIGN KEY (recipient_id) REFERENCES public.accesses(id) ON DELETE CASCADE;


--
-- TOC entry 3599 (class 2606 OID 19187)
-- Name: notifications fk_notifications_ticket_id_tickets; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_ticket_id_tickets FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- TOC entry 3600 (class 2606 OID 19192)
-- Name: question_frameworks fk_question_question_types_question_id_questions; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.question_frameworks
    ADD CONSTRAINT fk_question_question_types_question_id_questions FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE;


--
-- TOC entry 3601 (class 2606 OID 19197)
-- Name: question_frameworks fk_question_question_types_question_type_question_types; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.question_frameworks
    ADD CONSTRAINT fk_question_question_types_question_type_question_types FOREIGN KEY (framework) REFERENCES public.frameworks(label) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3602 (class 2606 OID 19202)
-- Name: question_technologies fk_question_technologies_question_id_questions; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.question_technologies
    ADD CONSTRAINT fk_question_technologies_question_id_questions FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE;


--
-- TOC entry 3597 (class 2606 OID 19177)
-- Name: frameworks fk_question_types_owner_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.frameworks
    ADD CONSTRAINT fk_question_types_owner_id_accesses FOREIGN KEY (owner_id) REFERENCES public.accesses(id) ON DELETE SET NULL;


--
-- TOC entry 3603 (class 2606 OID 19207)
-- Name: questions fk_questions_element_number_elements; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT fk_questions_element_number_elements FOREIGN KEY (element_number) REFERENCES public.elements(element_number);


--
-- TOC entry 3604 (class 2606 OID 19212)
-- Name: site_technologies fk_site_technologies_site_id_sites; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.site_technologies
    ADD CONSTRAINT fk_site_technologies_site_id_sites FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- TOC entry 3605 (class 2606 OID 19217)
-- Name: sites fk_sites_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT fk_sites_entity_id FOREIGN KEY (entity_id) REFERENCES public.entities(id) ON DELETE SET NULL;


--
-- TOC entry 3606 (class 2606 OID 19222)
-- Name: sites fk_sites_review_owner_id_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT fk_sites_review_owner_id_accesses FOREIGN KEY (review_owner_id) REFERENCES public.accesses(id) ON DELETE SET NULL;


--
-- TOC entry 3607 (class 2606 OID 19227)
-- Name: ticket_updates fk_ticket_updates_author_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.ticket_updates
    ADD CONSTRAINT fk_ticket_updates_author_accesses FOREIGN KEY (author) REFERENCES public.accesses(id);


--
-- TOC entry 3608 (class 2606 OID 19232)
-- Name: ticket_updates fk_ticket_updates_ticket_id_tickets; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.ticket_updates
    ADD CONSTRAINT fk_ticket_updates_ticket_id_tickets FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- TOC entry 3609 (class 2606 OID 19237)
-- Name: tickets fk_tickets_assigned_to_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_tickets_assigned_to_accesses FOREIGN KEY (assigned_to) REFERENCES public.accesses(id) ON DELETE SET NULL;


--
-- TOC entry 3610 (class 2606 OID 19242)
-- Name: tickets fk_tickets_created_by_accesses; Type: FK CONSTRAINT; Schema: public; Owner: demo_app
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_tickets_created_by_accesses FOREIGN KEY (created_by) REFERENCES public.accesses(id);


--
-- TOC entry 3761 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: demo_app
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


-- Completed on 2026-09-25 17:14:09 CEST

--
-- PostgreSQL database dump complete
--

