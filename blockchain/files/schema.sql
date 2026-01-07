-- PostgreSQL schema for energy database

-- Create energy table
CREATE TABLE IF NOT EXISTS energy (
    id SERIAL PRIMARY KEY,
    mwh INTEGER NOT NULL,
    time INTEGER NOT NULL
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_energy_time ON energy(time);
