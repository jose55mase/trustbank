-- Migration: Add duplicate_count column to lead_imports table
-- Feature: leads-export-deduplication
-- Requisito: 4.4

ALTER TABLE lead_imports ADD COLUMN duplicate_count INT DEFAULT 0;
