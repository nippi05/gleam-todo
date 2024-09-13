CREATE TABLE users(
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    password CHAR(255) NOT NULL
);
CREATE TABLE todos(
    id SERIAL PRIMARY KEY,
    creator BIGINT NULL,
    done BOOLEAN NOT NULL DEFAULT FALSE,
    content TEXT NOT NULL,
    CONSTRAINT todos_creator_foreign FOREIGN KEY(creator) REFERENCES users(id)
);