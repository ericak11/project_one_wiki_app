CREATE TABLE users (
  id            serial      PRIMARY KEY,
  name          varchar(64) NOT NULL,
  google_id     integer     NOT NULL,
  handle        varchar(64)
);

CREATE TABLE tags (
  id    serial       PRIMARY KEY,
  tag   varchar(64)  NOT NULL,
);

CREATE TABLE documents (
  id          serial       PRIMARY KEY,
  title       varchar(64)  NOT NULL,
  created_at  date         DEFAULT current_date
);



CREATE TABLE permissions
