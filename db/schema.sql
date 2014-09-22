DROP DATABASE IF EXISTS wiki_app;
CREATE DATABASE wiki_app;
\c wiki_app

DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS versions CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS permissions CASCADE;

CREATE TABLE documents (
  id          serial       PRIMARY KEY,
  title       varchar(127) NOT NULL,
  created_at  timestamp with time zone default now()
);

CREATE TABLE tags (
  id         serial       PRIMARY KEY,
  tag_name   varchar(255) NOT NULL
);

CREATE TABLE users (
  id           serial  PRIMARY KEY,
  user_name    varchar(255) NOT NULL,
  google_id    integer NOT NULL
);

CREATE TABLE permissions (
  id          serial  PRIMARY KEY,
  doc_id      integer REFERENCES  documents(id) NOT NULL,
  user_id     integer REFERENCES  users(id) NOT NULL,
  can_edit    boolean NOT NULL DEFAULT FALSE,
  doc_admin   boolean NOT NULL
);

CREATE TABLE versions (
  id          serial       PRIMARY KEY,
  content     varchar(4000) NOT NULL,
  editor_id   integer REFERENCES  users(id) NOT NULL,
  created_at  timestamp with time zone default now(),
  document_id integer REFERENCES  documents(id) NOT NULL
);
