CREATE TABLE "calls" (
	"id" bigint PRIMARY KEY NOT NULL,
	"caller" text NOT NULL,
	"asset" text NOT NULL,
	"is_long" boolean NOT NULL,
	"opened_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"resolved_at" timestamp with time zone,
	"entry_price" text NOT NULL,
	"exit_price" text,
	"return_bps" integer,
	"status" text NOT NULL,
	"won" boolean,
	"open_tx" text NOT NULL,
	"resolve_tx" text,
	"open_block" bigint NOT NULL
);
--> statement-breakpoint
CREATE TABLE "indexer_state" (
	"key" text PRIMARY KEY NOT NULL,
	"value" text NOT NULL
);
--> statement-breakpoint
CREATE INDEX "calls_caller_idx" ON "calls" USING btree ("caller");--> statement-breakpoint
CREATE INDEX "calls_status_idx" ON "calls" USING btree ("status");--> statement-breakpoint
CREATE INDEX "calls_expires_at_idx" ON "calls" USING btree ("expires_at");--> statement-breakpoint
CREATE INDEX "calls_resolved_at_idx" ON "calls" USING btree ("resolved_at");