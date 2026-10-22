// =============================================================================
// MassMates · Supabase database types
// =============================================================================
// GENERATED FILE -- do not edit by hand.
//
// Generated with the Supabase MCP tool
//   tools["supabase"]["generate_typescript_types"]()
// against the remote project khovpljkitslmjmonuzu (PostgreSQL 17.11),
// on 2026-10-22, as part of the A10 security & QA audit.
//
// Regenerate whenever a migration changes the schema:
//   supabase gen types typescript --project-id khovpljkitslmjmonuzu > supabase/types/database.ts
//
// The iOS client imports this file to type its Supabase queries.
// =============================================================================

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      account_deletion_requests: {
        Row: {
          completed_at: string | null
          confirmation_token: string
          confirmed_at: string | null
          expires_at: string
          id: string
          requested_at: string
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          completed_at?: string | null
          confirmation_token: string
          confirmed_at?: string | null
          expires_at?: string
          id?: string
          requested_at?: string
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          completed_at?: string | null
          confirmation_token?: string
          confirmed_at?: string | null
          expires_at?: string
          id?: string
          requested_at?: string
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "account_deletion_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      ad_view_tokens: {
        Row: {
          consumed_at: string | null
          created_at: string
          expires_at: string
          id: string
          reward_type: string
          transaction_id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          consumed_at?: string | null
          created_at?: string
          expires_at: string
          id?: string
          reward_type: string
          transaction_id: string
          updated_at?: string
          user_id: string
        }
        Update: {
          consumed_at?: string | null
          created_at?: string
          expires_at?: string
          id?: string
          reward_type?: string
          transaction_id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ad_view_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      amen_reactions: {
        Row: {
          created_at: string
          id: string
          post_id: string
          reaction_type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          post_id: string
          reaction_type?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          post_id?: string
          reaction_type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "amen_reactions_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "feed_posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "amen_reactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_log: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          id: number
          metadata: Json
          target_id: string | null
          target_type: string
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          id?: never
          metadata?: Json
          target_id?: string | null
          target_type: string
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          id?: never
          metadata?: Json
          target_id?: string | null
          target_type?: string
        }
        Relationships: []
      }
      chat_messages: {
        Row: {
          body: string
          created_at: string
          group_id: string
          hidden_at: string | null
          hidden_reason: string | null
          id: string
          is_hidden: boolean
          reply_to_id: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          group_id: string
          hidden_at?: string | null
          hidden_reason?: string | null
          id?: string
          is_hidden?: boolean
          reply_to_id?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          group_id?: string
          hidden_at?: string | null
          hidden_reason?: string | null
          id?: string
          is_hidden?: boolean
          reply_to_id?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_messages_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_reply_to_id_fkey"
            columns: ["reply_to_id"]
            isOneToOne: false
            referencedRelation: "chat_messages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      check_in_destinations: {
        Row: {
          check_in_id: string
          created_at: string
          group_id: string
          id: string
        }
        Insert: {
          check_in_id: string
          created_at?: string
          group_id: string
          id?: string
        }
        Update: {
          check_in_id?: string
          created_at?: string
          group_id?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "check_in_destinations_check_in_id_fkey"
            columns: ["check_in_id"]
            isOneToOne: false
            referencedRelation: "check_ins"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "check_in_destinations_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
      check_ins: {
        Row: {
          created_at: string
          id: string
          local_date: string
          photo_path: string | null
          points: number
          practice_kind: Database["public"]["Enums"]["practice_kind"]
          reflection_text: string | null
          sharing: string
          timezone: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          local_date: string
          photo_path?: string | null
          points?: number
          practice_kind: Database["public"]["Enums"]["practice_kind"]
          reflection_text?: string | null
          sharing: string
          timezone: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          local_date?: string
          photo_path?: string | null
          points?: number
          practice_kind?: Database["public"]["Enums"]["practice_kind"]
          reflection_text?: string | null
          sharing?: string
          timezone?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "check_ins_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      content_reports: {
        Row: {
          created_at: string
          details: string | null
          group_id: string | null
          id: string
          reason: string
          reporter_id: string
          resolved_at: string | null
          resolved_by: string | null
          status: string
          target_id: string
          target_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          details?: string | null
          group_id?: string | null
          id?: string
          reason: string
          reporter_id: string
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          target_id: string
          target_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          details?: string | null
          group_id?: string | null
          id?: string
          reason?: string
          reporter_id?: string
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          target_id?: string
          target_type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "content_reports_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "content_reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      daily_readings: {
        Row: {
          calendar_date: string
          created_at: string
          first_reading_ref: string | null
          first_reading_text: string | null
          gospel_ref: string | null
          gospel_text: string | null
          id: string
          is_complete: boolean
          liturgical_color: string | null
          psalm_ref: string | null
          psalm_text: string | null
          translation: string
          updated_at: string
        }
        Insert: {
          calendar_date: string
          created_at?: string
          first_reading_ref?: string | null
          first_reading_text?: string | null
          gospel_ref?: string | null
          gospel_text?: string | null
          id?: string
          is_complete?: boolean
          liturgical_color?: string | null
          psalm_ref?: string | null
          psalm_text?: string | null
          translation?: string
          updated_at?: string
        }
        Update: {
          calendar_date?: string
          created_at?: string
          first_reading_ref?: string | null
          first_reading_text?: string | null
          gospel_ref?: string | null
          gospel_text?: string | null
          id?: string
          is_complete?: boolean
          liturgical_color?: string | null
          psalm_ref?: string | null
          psalm_text?: string | null
          translation?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "daily_readings_calendar_date_fkey"
            columns: ["calendar_date"]
            isOneToOne: true
            referencedRelation: "liturgical_days"
            referencedColumns: ["calendar_date"]
          },
        ]
      }
      device_tokens: {
        Row: {
          apns_token: string
          app_version: string | null
          created_at: string
          environment: string
          id: string
          is_active: boolean
          last_seen_at: string
          platform: string
          user_id: string
        }
        Insert: {
          apns_token: string
          app_version?: string | null
          created_at?: string
          environment?: string
          id?: string
          is_active?: boolean
          last_seen_at?: string
          platform?: string
          user_id: string
        }
        Update: {
          apns_token?: string
          app_version?: string | null
          created_at?: string
          environment?: string
          id?: string
          is_active?: boolean
          last_seen_at?: string
          platform?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "device_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      feed_post_comments: {
        Row: {
          body: string
          created_at: string
          group_id: string
          hidden_at: string | null
          hidden_reason: string | null
          id: string
          is_hidden: boolean
          post_id: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          group_id: string
          hidden_at?: string | null
          hidden_reason?: string | null
          id?: string
          is_hidden?: boolean
          post_id: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          group_id?: string
          hidden_at?: string | null
          hidden_reason?: string | null
          id?: string
          is_hidden?: boolean
          post_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "feed_post_comments_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feed_post_comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "feed_posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feed_post_comments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      feed_posts: {
        Row: {
          check_in_id: string | null
          created_at: string
          group_id: string
          hidden_reason: string | null
          id: string
          is_hidden: boolean
          photo_path: string | null
          points: number
          practice_kind: Database["public"]["Enums"]["practice_kind"]
          reflection_text: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          check_in_id?: string | null
          created_at?: string
          group_id: string
          hidden_reason?: string | null
          id?: string
          is_hidden?: boolean
          photo_path?: string | null
          points?: number
          practice_kind: Database["public"]["Enums"]["practice_kind"]
          reflection_text?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          check_in_id?: string | null
          created_at?: string
          group_id?: string
          hidden_reason?: string | null
          id?: string
          is_hidden?: boolean
          photo_path?: string | null
          points?: number
          practice_kind?: Database["public"]["Enums"]["practice_kind"]
          reflection_text?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "feed_posts_check_in_id_fkey"
            columns: ["check_in_id"]
            isOneToOne: false
            referencedRelation: "check_ins"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feed_posts_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feed_posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      group_featured: {
        Row: {
          created_at: string
          display_order: number
          ends_on: string | null
          group_id: string
          is_featured: boolean
          starts_on: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          display_order?: number
          ends_on?: string | null
          group_id: string
          is_featured?: boolean
          starts_on?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          display_order?: number
          ends_on?: string | null
          group_id?: string
          is_featured?: boolean
          starts_on?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "group_featured_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: true
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
      group_invites: {
        Row: {
          code: string
          created_at: string
          created_by: string
          group_id: string
          id: string
          max_uses: number
          revoked_at: string | null
          updated_at: string
          uses: number
        }
        Insert: {
          code: string
          created_at?: string
          created_by: string
          group_id: string
          id?: string
          max_uses?: number
          revoked_at?: string | null
          updated_at?: string
          uses?: number
        }
        Update: {
          code?: string
          created_at?: string
          created_by?: string
          group_id?: string
          id?: string
          max_uses?: number
          revoked_at?: string | null
          updated_at?: string
          uses?: number
        }
        Relationships: [
          {
            foreignKeyName: "group_invites_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_invites_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
      group_members: {
        Row: {
          group_id: string
          id: string
          joined_at: string
          role: Database["public"]["Enums"]["member_role"]
          user_id: string
        }
        Insert: {
          group_id: string
          id?: string
          joined_at?: string
          role?: Database["public"]["Enums"]["member_role"]
          user_id: string
        }
        Update: {
          group_id?: string
          id?: string
          joined_at?: string
          role?: Database["public"]["Enums"]["member_role"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "group_members_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      groups: {
        Row: {
          archived_at: string | null
          cover_path: string | null
          created_at: string
          created_by: string | null
          description: string | null
          ends_on: string | null
          goal_target: number | null
          group_type: Database["public"]["Enums"]["group_type"]
          id: string
          invite_code: string | null
          name: string
          scoring_mode: Database["public"]["Enums"]["scoring_mode"]
          sharing_requirement: Database["public"]["Enums"]["sharing_requirement"]
          starts_on: string | null
          updated_at: string
        }
        Insert: {
          archived_at?: string | null
          cover_path?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          ends_on?: string | null
          goal_target?: number | null
          group_type?: Database["public"]["Enums"]["group_type"]
          id?: string
          invite_code?: string | null
          name: string
          scoring_mode?: Database["public"]["Enums"]["scoring_mode"]
          sharing_requirement?: Database["public"]["Enums"]["sharing_requirement"]
          starts_on?: string | null
          updated_at?: string
        }
        Update: {
          archived_at?: string | null
          cover_path?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          ends_on?: string | null
          goal_target?: number | null
          group_type?: Database["public"]["Enums"]["group_type"]
          id?: string
          invite_code?: string | null
          name?: string
          scoring_mode?: Database["public"]["Enums"]["scoring_mode"]
          sharing_requirement?: Database["public"]["Enums"]["sharing_requirement"]
          starts_on?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "groups_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      guardian_angel_opt_ins: {
        Row: {
          created_at: string
          group_id: string
          id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          group_id: string
          id?: string
          user_id: string
        }
        Update: {
          created_at?: string
          group_id?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "guardian_angel_opt_ins_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "guardian_angel_opt_ins_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      guardian_angel_pairings: {
        Row: {
          created_at: string
          cycle_ends_on: string
          cycle_key: string
          cycle_starts_on: string
          group_id: string
          guardian_id: string
          id: string
          is_active: boolean
          protected_id: string
          revealed_at: string | null
        }
        Insert: {
          created_at?: string
          cycle_ends_on: string
          cycle_key: string
          cycle_starts_on: string
          group_id: string
          guardian_id: string
          id?: string
          is_active?: boolean
          protected_id: string
          revealed_at?: string | null
        }
        Update: {
          created_at?: string
          cycle_ends_on?: string
          cycle_key?: string
          cycle_starts_on?: string
          group_id?: string
          guardian_id?: string
          id?: string
          is_active?: boolean
          protected_id?: string
          revealed_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "guardian_angel_pairings_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "guardian_angel_pairings_guardian_id_fkey"
            columns: ["guardian_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "guardian_angel_pairings_protected_id_fkey"
            columns: ["protected_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      guardian_nudges: {
        Row: {
          created_at: string
          cycle_key: string
          group_id: string
          id: string
          local_date: string
          pairing_id: string
          protected_id: string
          sender_id: string
        }
        Insert: {
          created_at?: string
          cycle_key: string
          group_id: string
          id?: string
          local_date: string
          pairing_id: string
          protected_id: string
          sender_id: string
        }
        Update: {
          created_at?: string
          cycle_key?: string
          group_id?: string
          id?: string
          local_date?: string
          pairing_id?: string
          protected_id?: string
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "guardian_nudges_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "guardian_nudges_pairing_id_fkey"
            columns: ["pairing_id"]
            isOneToOne: false
            referencedRelation: "guardian_angel_pairings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "guardian_nudges_protected_id_fkey"
            columns: ["protected_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "guardian_nudges_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      intention_prayers: {
        Row: {
          created_at: string
          id: string
          intention_id: string
          prayer_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          intention_id: string
          prayer_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          intention_id?: string
          prayer_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "intention_prayers_intention_id_fkey"
            columns: ["intention_id"]
            isOneToOne: false
            referencedRelation: "prayer_intentions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "intention_prayers_prayer_id_fkey"
            columns: ["prayer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      liturgical_days: {
        Row: {
          calendar_date: string
          celebration: string | null
          created_at: string
          id: string
          liturgical_color: string
          notes: string | null
          rank: string | null
          season: Database["public"]["Enums"]["liturgical_season"]
          updated_at: string
        }
        Insert: {
          calendar_date: string
          celebration?: string | null
          created_at?: string
          id?: string
          liturgical_color: string
          notes?: string | null
          rank?: string | null
          season: Database["public"]["Enums"]["liturgical_season"]
          updated_at?: string
        }
        Update: {
          calendar_date?: string
          celebration?: string | null
          created_at?: string
          id?: string
          liturgical_color?: string
          notes?: string | null
          rank?: string | null
          season?: Database["public"]["Enums"]["liturgical_season"]
          updated_at?: string
        }
        Relationships: []
      }
      moderation_actions: {
        Row: {
          action_type: string
          actor_id: string
          created_at: string
          group_id: string | null
          id: string
          metadata: Json
          reason: string | null
          report_id: string | null
          target_id: string
          target_type: string
        }
        Insert: {
          action_type: string
          actor_id: string
          created_at?: string
          group_id?: string | null
          id?: string
          metadata?: Json
          reason?: string | null
          report_id?: string | null
          target_id: string
          target_type: string
        }
        Update: {
          action_type?: string
          actor_id?: string
          created_at?: string
          group_id?: string | null
          id?: string
          metadata?: Json
          reason?: string | null
          report_id?: string | null
          target_id?: string
          target_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "moderation_actions_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderation_actions_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderation_actions_report_id_fkey"
            columns: ["report_id"]
            isOneToOne: false
            referencedRelation: "content_reports"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_outbox: {
        Row: {
          attempts: number
          body: string
          channel: string
          created_at: string
          dedupe_key: string
          group_id: string | null
          id: string
          last_error: string | null
          notification_type: string
          payload: Json
          scheduled_at: string
          sent_at: string | null
          status: string
          title: string
          user_id: string
        }
        Insert: {
          attempts?: number
          body: string
          channel?: string
          created_at?: string
          dedupe_key: string
          group_id?: string | null
          id?: string
          last_error?: string | null
          notification_type: string
          payload?: Json
          scheduled_at?: string
          sent_at?: string | null
          status?: string
          title: string
          user_id: string
        }
        Update: {
          attempts?: number
          body?: string
          channel?: string
          created_at?: string
          dedupe_key?: string
          group_id?: string | null
          id?: string
          last_error?: string | null
          notification_type?: string
          payload?: Json
          scheduled_at?: string
          sent_at?: string | null
          status?: string
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_outbox_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_outbox_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      pinned_notices: {
        Row: {
          author_id: string
          body: string
          created_at: string
          group_id: string
          id: string
          is_active: boolean
          updated_at: string
        }
        Insert: {
          author_id: string
          body: string
          created_at?: string
          group_id: string
          id?: string
          is_active?: boolean
          updated_at?: string
        }
        Update: {
          author_id?: string
          body?: string
          created_at?: string
          group_id?: string
          id?: string
          is_active?: boolean
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "pinned_notices_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pinned_notices_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
      practice_points: {
        Row: {
          created_at: string
          group_id: string | null
          id: string
          points: number
          practice_kind: Database["public"]["Enums"]["practice_kind"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          group_id?: string | null
          id?: string
          points: number
          practice_kind: Database["public"]["Enums"]["practice_kind"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          group_id?: string | null
          id?: string
          points?: number
          practice_kind?: Database["public"]["Enums"]["practice_kind"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "practice_points_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
      prayer_intentions: {
        Row: {
          body: string
          created_at: string
          group_id: string
          id: string
          is_hidden: boolean
          prayer_count: number
          updated_at: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          group_id: string
          id?: string
          is_hidden?: boolean
          prayer_count?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          group_id?: string
          id?: string
          is_hidden?: boolean
          prayer_count?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "prayer_intentions_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "prayer_intentions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          ad_consent_analytics: boolean
          ad_personalization: boolean
          avatar_path: string | null
          city: string | null
          created_at: string
          deleted_at: string | null
          display_name: string
          guardian_angel_opt_in: boolean
          id: string
          locale: string
          parish: string | null
          rule_of_life: Json
          timezone: string
          updated_at: string
        }
        Insert: {
          ad_consent_analytics?: boolean
          ad_personalization?: boolean
          avatar_path?: string | null
          city?: string | null
          created_at?: string
          deleted_at?: string | null
          display_name: string
          guardian_angel_opt_in?: boolean
          id: string
          locale?: string
          parish?: string | null
          rule_of_life?: Json
          timezone?: string
          updated_at?: string
        }
        Update: {
          ad_consent_analytics?: boolean
          ad_personalization?: boolean
          avatar_path?: string | null
          city?: string | null
          created_at?: string
          deleted_at?: string | null
          display_name?: string
          guardian_angel_opt_in?: boolean
          id?: string
          locale?: string
          parish?: string | null
          rule_of_life?: Json
          timezone?: string
          updated_at?: string
        }
        Relationships: []
      }
      reward_grants: {
        Row: {
          ad_network: string | null
          consumed_at: string | null
          created_at: string
          expires_at: string | null
          granted_at: string
          id: string
          metadata: Json
          reward_type: string
          source: string
          status: string
          transaction_id: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          ad_network?: string | null
          consumed_at?: string | null
          created_at?: string
          expires_at?: string | null
          granted_at?: string
          id?: string
          metadata?: Json
          reward_type: string
          source: string
          status?: string
          transaction_id?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          ad_network?: string | null
          consumed_at?: string | null
          created_at?: string
          expires_at?: string | null
          granted_at?: string
          id?: string
          metadata?: Json
          reward_type?: string
          source?: string
          status?: string
          transaction_id?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reward_grants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      saint_icons: {
        Row: {
          created_at: string
          icon_sf_symbol: string
          id: string
          is_active: boolean
          name: string
          saint_id: string | null
          season: Database["public"]["Enums"]["liturgical_season"] | null
          slug: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          icon_sf_symbol: string
          id?: string
          is_active?: boolean
          name: string
          saint_id?: string | null
          season?: Database["public"]["Enums"]["liturgical_season"] | null
          slug: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          icon_sf_symbol?: string
          id?: string
          is_active?: boolean
          name?: string
          saint_id?: string | null
          season?: Database["public"]["Enums"]["liturgical_season"] | null
          slug?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "saint_icons_saint_id_fkey"
            columns: ["saint_id"]
            isOneToOne: false
            referencedRelation: "saints"
            referencedColumns: ["id"]
          },
        ]
      }
      saints: {
        Row: {
          biography: string | null
          calendar_date: string
          created_at: string
          id: string
          kind: string
          name: string
          patronage: string | null
          updated_at: string
        }
        Insert: {
          biography?: string | null
          calendar_date: string
          created_at?: string
          id?: string
          kind: string
          name: string
          patronage?: string | null
          updated_at?: string
        }
        Update: {
          biography?: string | null
          calendar_date?: string
          created_at?: string
          id?: string
          kind?: string
          name?: string
          patronage?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      slot_unlocks: {
        Row: {
          created_at: string
          expires_at: string | null
          id: string
          kind: string
          notes: string | null
          source: string
          starts_at: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          expires_at?: string | null
          id?: string
          kind: string
          notes?: string | null
          source: string
          starts_at?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          expires_at?: string | null
          id?: string
          kind?: string
          notes?: string | null
          source?: string
          starts_at?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "slot_unlocks_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      sponsored_challenges: {
        Row: {
          coupon_code: string | null
          coupon_url: string | null
          created_at: string
          description: string | null
          display_order: number
          ends_on: string | null
          featured_group_id: string | null
          group_id: string
          headline: string
          id: string
          is_active: boolean
          sponsor_id: string
          starts_on: string | null
          updated_at: string
        }
        Insert: {
          coupon_code?: string | null
          coupon_url?: string | null
          created_at?: string
          description?: string | null
          display_order?: number
          ends_on?: string | null
          featured_group_id?: string | null
          group_id: string
          headline: string
          id?: string
          is_active?: boolean
          sponsor_id: string
          starts_on?: string | null
          updated_at?: string
        }
        Update: {
          coupon_code?: string | null
          coupon_url?: string | null
          created_at?: string
          description?: string | null
          display_order?: number
          ends_on?: string | null
          featured_group_id?: string | null
          group_id?: string
          headline?: string
          id?: string
          is_active?: boolean
          sponsor_id?: string
          starts_on?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "sponsored_challenges_featured_group_id_fkey"
            columns: ["featured_group_id"]
            isOneToOne: false
            referencedRelation: "group_featured"
            referencedColumns: ["group_id"]
          },
          {
            foreignKeyName: "sponsored_challenges_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sponsored_challenges_sponsor_id_fkey"
            columns: ["sponsor_id"]
            isOneToOne: false
            referencedRelation: "sponsors"
            referencedColumns: ["id"]
          },
        ]
      }
      sponsors: {
        Row: {
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          logo_path: string | null
          name: string
          slug: string
          updated_at: string
          website_url: string | null
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          logo_path?: string | null
          name: string
          slug: string
          updated_at?: string
          website_url?: string | null
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          logo_path?: string | null
          name?: string
          slug?: string
          updated_at?: string
          website_url?: string | null
        }
        Relationships: []
      }
      ssv_receipts: {
        Row: {
          ad_type: string | null
          ad_value: number | null
          created_at: string
          currency: string | null
          id: string
          outcome: string
          package_name: string | null
          reason: string | null
          received_at: string
          reward_type: string | null
          transaction_id: string | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          ad_type?: string | null
          ad_value?: number | null
          created_at?: string
          currency?: string | null
          id?: string
          outcome: string
          package_name?: string | null
          reason?: string | null
          received_at?: string
          reward_type?: string | null
          transaction_id?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          ad_type?: string | null
          ad_value?: number | null
          created_at?: string
          currency?: string | null
          id?: string
          outcome?: string
          package_name?: string | null
          reason?: string | null
          received_at?: string
          reward_type?: string | null
          transaction_id?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ssv_receipts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      streak_events: {
        Row: {
          created_at: string
          event_type: string
          id: string
          local_date: string
          streak_after: number
          user_id: string
        }
        Insert: {
          created_at?: string
          event_type: string
          id?: string
          local_date: string
          streak_after: number
          user_id: string
        }
        Update: {
          created_at?: string
          event_type?: string
          id?: string
          local_date?: string
          streak_after?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "streak_events_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      streak_mercy_grants: {
        Row: {
          expires_at: string
          granted_at: string
          id: string
          used_at: string | null
          user_id: string
        }
        Insert: {
          expires_at?: string
          granted_at?: string
          id?: string
          used_at?: string | null
          user_id: string
        }
        Update: {
          expires_at?: string
          granted_at?: string
          id?: string
          used_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "streak_mercy_grants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      streak_mercy_uses: {
        Row: {
          created_at: string
          id: string
          repairs_date: string
          used_on: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          repairs_date: string
          used_on: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          repairs_date?: string
          used_on?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "streak_mercy_uses_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      streaks: {
        Row: {
          current_streak: number
          last_practice_date: string | null
          longest_streak: number
          total_practices: number
          updated_at: string
          user_id: string
        }
        Insert: {
          current_streak?: number
          last_practice_date?: string | null
          longest_streak?: number
          total_practices?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          current_streak?: number
          last_practice_date?: string | null
          longest_streak?: number
          total_practices?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "streaks_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
          id: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
          id?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_blocks_blocked_id_fkey"
            columns: ["blocked_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_blocks_blocker_id_fkey"
            columns: ["blocker_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_saint_unlocks: {
        Row: {
          created_at: string
          expires_at: string
          granted_at: string
          id: string
          saint_icon_id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          expires_at: string
          granted_at?: string
          id?: string
          saint_icon_id: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          expires_at?: string
          granted_at?: string
          id?: string
          saint_icon_id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_saint_unlocks_saint_icon_id_fkey"
            columns: ["saint_icon_id"]
            isOneToOne: false
            referencedRelation: "saint_icons"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_saint_unlocks_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      v_target_report_counts: {
        Row: {
          report_count: number | null
          target_id: string | null
          target_type: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      admin_delete_post: { Args: { p_post_id: string }; Returns: Json }
      attach_updated_at: { Args: { p_table: unknown }; Returns: undefined }
      begin_ad_reward: { Args: { p_reward_type: string }; Returns: Json }
      block_user: { Args: { p_blocked_id: string }; Returns: Json }
      claim_notification_outbox: { Args: { p_limit?: number }; Returns: Json[] }
      clear_pinned_notice: { Args: { p_group_id: string }; Returns: Json }
      complete_notification_outbox: {
        Args: {
          p_error?: string
          p_outbox_id: string
          p_retry_at?: string
          p_status: string
        }
        Returns: Json
      }
      confirm_account_deletion: { Args: { p_token: string }; Returns: Json }
      consume_reward: { Args: { p_grant_id: string }; Returns: Json }
      create_chat_message: {
        Args: { p_body: string; p_group_id: string; p_reply_to_id?: string }
        Returns: Json
      }
      create_feed_post_comment: {
        Args: { p_body: string; p_post_id: string }
        Returns: Json
      }
      create_group: {
        Args: {
          p_description?: string
          p_ends_on?: string
          p_goal_target?: number
          p_group_type?: Database["public"]["Enums"]["group_type"]
          p_name: string
          p_scoring_mode?: Database["public"]["Enums"]["scoring_mode"]
          p_sharing_requirement?: Database["public"]["Enums"]["sharing_requirement"]
          p_starts_on?: string
        }
        Returns: Json
      }
      create_prayer_intention: {
        Args: { p_body: string; p_group_id: string }
        Returns: Json
      }
      create_signed_witness_url: {
        Args: { p_expires_in?: number; p_object_path: string }
        Returns: Json
      }
      create_signed_witness_urls: {
        Args: { p_expires_in?: number; p_paths: string[] }
        Returns: Json
      }
      current_user_id: { Args: never; Returns: string }
      deactivate_device_token: { Args: { p_token_id: string }; Returns: Json }
      delete_feed_post_comment: {
        Args: { p_comment_id: string }
        Returns: Json
      }
      delete_my_account_request: { Args: never; Returns: Json }
      dispatch_push_notifications: { Args: never; Returns: Json }
      emit_prayer_notification: {
        Args: { p_intention_id: string; p_prayer_id: string }
        Returns: Json
      }
      get_chat_messages: {
        Args: { p_before?: string; p_group_id: string; p_limit?: number }
        Returns: Json
      }
      get_consistency_heatmap: {
        Args: { p_from: string; p_to: string }
        Returns: Json
      }
      get_feed_post_comments: {
        Args: { p_before?: string; p_limit?: number; p_post_id: string }
        Returns: Json
      }
      get_feed_posts: {
        Args: { p_before?: string; p_group_id: string; p_limit?: number }
        Returns: Json
      }
      get_group_progress: { Args: { p_group_id: string }; Returns: Json }
      get_liturgical_calendar: { Args: { p_year: number }; Returns: Json }
      get_moderation_actions: { Args: { p_group_id: string }; Returns: Json }
      get_moderation_queue: { Args: { p_group_id: string }; Returns: Json }
      get_my_profile: { Args: never; Returns: Json }
      get_prayer_intentions: {
        Args: { p_before?: string; p_group_id: string; p_limit?: number }
        Returns: Json
      }
      get_rule_of_life_ring: { Args: { p_local_date?: string }; Returns: Json }
      get_streak_summary: { Args: never; Returns: Json }
      get_today_liturgy: { Args: never; Returns: Json }
      grant_reward: {
        Args: {
          p_expires_days?: number
          p_metadata?: Json
          p_reward_type: string
          p_source: string
          p_transaction_id?: string
          p_user_id: string
        }
        Returns: Json
      }
      grant_slot_unlock: {
        Args: {
          p_days?: number
          p_kind: string
          p_notes?: string
          p_source: string
          p_user_id: string
        }
        Returns: Json
      }
      grant_streak_mercy: {
        Args: { p_expires_at?: string; p_user_id: string }
        Returns: Json
      }
      guardian_angel_state: { Args: { p_group_id: string }; Returns: Json }
      hide_content: {
        Args: { p_reason: string; p_target_id: string; p_target_type: string }
        Returns: Json
      }
      insert_feed_post: {
        Args: {
          p_check_in_id: string
          p_group_id: string
          p_photo_path?: string
          p_points?: number
          p_practice_kind: Database["public"]["Enums"]["practice_kind"]
          p_reflection_text?: string
          p_user_id: string
        }
        Returns: Json
      }
      is_any_group_admin: { Args: never; Returns: boolean }
      is_blocked: { Args: { p_other_id: string }; Returns: boolean }
      is_group_admin: { Args: { p_group_id: string }; Returns: boolean }
      is_group_member: { Args: { p_group_id: string }; Returns: boolean }
      is_group_member_of_any: { Args: never; Returns: boolean }
      join_featured_challenge: { Args: { p_group_id: string }; Returns: Json }
      join_group_by_code: { Args: { p_code: string }; Returns: Json }
      leave_group: { Args: { p_group_id: string }; Returns: Json }
      list_blocked_users: { Args: never; Returns: Json }
      list_featured_challenges: { Args: never; Returns: Json }
      my_group_slots: { Args: never; Returns: Json }
      my_groups: { Args: never; Returns: Json }
      my_guardian_assignment: { Args: { p_group_id: string }; Returns: Json }
      my_rewards: { Args: never; Returns: Json }
      opt_in_to_guardian_angel: {
        Args: { p_group_id: string; p_opt_in: boolean }
        Returns: Json
      }
      pgtap_policy_count: {
        Args: { p_cmd?: string; p_table: unknown }
        Returns: number
      }
      pgtap_rls_enabled: { Args: { p_table: unknown }; Returns: boolean }
      pgtap_rls_forced: { Args: { p_table: unknown }; Returns: boolean }
      pgtap_summary: { Args: never; Returns: Json }
      preview_group_by_code: { Args: { p_code: string }; Returns: Json }
      probe_wrapper: { Args: { p_a?: string }; Returns: Json }
      register_device_token: {
        Args: {
          p_apns_token: string
          p_app_version?: string
          p_environment?: string
          p_platform?: string
        }
        Returns: Json
      }
      remove_member: {
        Args: { p_group_id: string; p_member_id: string }
        Returns: Json
      }
      report_content: {
        Args: {
          p_details?: string
          p_group_id?: string
          p_reason: string
          p_target_id: string
          p_target_type: string
        }
        Returns: Json
      }
      request_account_deletion: { Args: never; Returns: Json }
      reset_invite_code: { Args: { p_group_id: string }; Returns: Json }
      resolve_report: {
        Args: { p_note?: string; p_report_id: string; p_status: string }
        Returns: Json
      }
      reveal_guardian_identities: {
        Args: { p_group_id: string }
        Returns: Json
      }
      run_guardian_angel_pairing: {
        Args: {
          p_cycle_key?: string
          p_cycle_starts_on?: string
          p_group_id: string
        }
        Returns: Json
      }
      send_guardian_nudge: {
        Args: { p_group_id: string; p_local_date?: string }
        Returns: Json
      }
      set_featured_group: {
        Args: {
          p_display_order?: number
          p_ends_on?: string
          p_group_id: string
          p_is_featured?: boolean
          p_starts_on?: string
        }
        Returns: Json
      }
      set_pinned_notice: {
        Args: { p_body: string; p_group_id: string }
        Returns: Json
      }
      set_practice_points: {
        Args: {
          p_group_id: string
          p_points: number
          p_practice: Database["public"]["Enums"]["practice_kind"]
        }
        Returns: Json
      }
      soft_delete_chat_message: {
        Args: { p_message_id: string }
        Returns: Json
      }
      soft_delete_feed_post: { Args: { p_post_id: string }; Returns: Json }
      soft_delete_feed_post_comment: {
        Args: { p_comment_id: string }
        Returns: Json
      }
      submit_check_in: {
        Args: {
          p_group_ids?: string[]
          p_local_date?: string
          p_photo_path?: string
          p_practice: Database["public"]["Enums"]["practice_kind"]
          p_reflection?: string
          p_sharing: string
          p_timezone?: string
        }
        Returns: Json
      }
      sweep_guardian_angel_pairings: {
        Args: { p_scope?: string }
        Returns: Json
      }
      sweep_reveal_guardian_identities: { Args: never; Returns: Json }
      toggle_amen: {
        Args: { p_post_id: string; p_reaction_type?: string }
        Returns: Json
      }
      toggle_prayed_for: { Args: { p_intention_id: string }; Returns: Json }
      transfer_admin: {
        Args: { p_group_id: string; p_new_admin_id: string }
        Returns: Json
      }
      unblock_user: { Args: { p_blocked_id: string }; Returns: Json }
      update_ad_consent: {
        Args: { p_analytics: boolean; p_personalization: boolean }
        Returns: Json
      }
      update_my_profile: {
        Args: {
          p_ad_consent_analytics?: boolean
          p_ad_personalization?: boolean
          p_avatar_path?: string
          p_city?: string
          p_display_name?: string
          p_locale?: string
          p_parish?: string
          p_rule_of_life?: Json
          p_timezone?: string
        }
        Returns: Json
      }
      use_streak_mercy: { Args: { p_repairs_date: string }; Returns: Json }
    }
    Enums: {
      group_type: "fraternity" | "challenge"
      liturgical_season:
        | "advent"
        | "christmas"
        | "lent"
        | "easter"
        | "ordinary_time"
      member_role: "admin" | "member"
      practice_kind:
        | "rosary"
        | "holy_mass"
        | "daily_gospel"
        | "adoration"
        | "mental_prayer"
        | "spiritual_reading"
        | "fasting"
        | "confession"
      scoring_mode: "faithful_days" | "collective_treasure" | "custom_points"
      sharing_requirement: "open" | "written_fruit" | "photo_witness"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      group_type: ["fraternity", "challenge"],
      liturgical_season: [
        "advent",
        "christmas",
        "lent",
        "easter",
        "ordinary_time",
      ],
      member_role: ["admin", "member"],
      practice_kind: [
        "rosary",
        "holy_mass",
        "daily_gospel",
        "adoration",
        "mental_prayer",
        "spiritual_reading",
        "fasting",
        "confession",
      ],
      scoring_mode: ["faithful_days", "collective_treasure", "custom_points"],
      sharing_requirement: ["open", "written_fruit", "photo_witness"],
    },
  },
} as const
