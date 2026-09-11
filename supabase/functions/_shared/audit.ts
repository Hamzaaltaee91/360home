// Shared audit logging helper for Edge Functions.
//
// Records sensitive operations (verification decisions, account deletions,
// role modifications) into the `audit_logs` table using the service role
// client. Failures are swallowed so auditing never breaks the primary
// operation.

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export interface AuditEntry {
  actorId: string | null;
  action: string;
  entityType: string;
  entityId: string | null;
  metadata?: Record<string, unknown>;
}

/**
 * Writes an audit log entry. Never throws: audit failures are logged and
 * ignored so they cannot break the caller's primary operation.
 */
export async function writeAuditLog(
  client: SupabaseClient,
  entry: AuditEntry,
): Promise<void> {
  try {
    const { error } = await client.rpc("write_audit_log", {
      p_actor_id: entry.actorId,
      p_action: entry.action,
      p_entity_type: entry.entityType,
      p_entity_id: entry.entityId,
      p_metadata: entry.metadata ?? {},
    });
    if (error) {
      console.error("audit log write failed:", error.message);
    }
  } catch (err) {
    console.error("audit log write threw:", err);
  }
}
