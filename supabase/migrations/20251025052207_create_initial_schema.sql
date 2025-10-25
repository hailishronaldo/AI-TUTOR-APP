/*
  # Create Initial Schema for AI Tutor App

  1. New Tables
    - `user_profiles`
      - `id` (uuid, primary key) - links to Firebase auth user
      - `email` (text, nullable) - user email
      - `display_name` (text, nullable) - user display name
      - `is_anonymous` (boolean, default false) - tracks anonymous users
      - `created_at` (timestamptz) - account creation time
      - `updated_at` (timestamptz) - last update time
    
    - `topic_details`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key) - links to user_profiles
      - `topic_id` (text) - identifier for the topic
      - `topic_title` (text) - topic name
      - `summary` (text) - tutorial summary
      - `steps` (jsonb) - tutorial steps data
      - `created_at` (timestamptz) - when tutorial was generated
      - `updated_at` (timestamptz) - last update time
    
    - `visited_topics`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key) - links to user_profiles
      - `topic_id` (text) - identifier for the topic
      - `visit_count` (integer, default 1) - number of visits
      - `last_visited_at` (timestamptz) - most recent visit time
      - `progress` (numeric, default 0) - completion percentage (0-100)
      - `created_at` (timestamptz) - first visit time
    
    - `chat_messages`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key) - links to user_profiles
      - `role` (text) - 'user' or 'assistant'
      - `content` (text) - message content
      - `created_at` (timestamptz) - message timestamp
    
  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their own data
    - Add policies for anonymous users to access their own data
*/

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY,
  email text,
  display_name text,
  is_anonymous boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (id::text = auth.uid()::text);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (id::text = auth.uid()::text);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (id::text = auth.uid()::text)
  WITH CHECK (id::text = auth.uid()::text);

CREATE POLICY "Users can delete own profile"
  ON user_profiles FOR DELETE
  TO authenticated
  USING (id::text = auth.uid()::text);

-- Create topic_details table
CREATE TABLE IF NOT EXISTS topic_details (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  topic_id text NOT NULL,
  topic_title text NOT NULL,
  summary text,
  steps jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, topic_id)
);

ALTER TABLE topic_details ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own topic details"
  ON topic_details FOR SELECT
  TO authenticated
  USING (user_id::text = auth.uid()::text);

CREATE POLICY "Users can insert own topic details"
  ON topic_details FOR INSERT
  TO authenticated
  WITH CHECK (user_id::text = auth.uid()::text);

CREATE POLICY "Users can update own topic details"
  ON topic_details FOR UPDATE
  TO authenticated
  USING (user_id::text = auth.uid()::text)
  WITH CHECK (user_id::text = auth.uid()::text);

CREATE POLICY "Users can delete own topic details"
  ON topic_details FOR DELETE
  TO authenticated
  USING (user_id::text = auth.uid()::text);

-- Create visited_topics table
CREATE TABLE IF NOT EXISTS visited_topics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  topic_id text NOT NULL,
  visit_count integer DEFAULT 1,
  last_visited_at timestamptz DEFAULT now(),
  progress numeric DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, topic_id)
);

ALTER TABLE visited_topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own visited topics"
  ON visited_topics FOR SELECT
  TO authenticated
  USING (user_id::text = auth.uid()::text);

CREATE POLICY "Users can insert own visited topics"
  ON visited_topics FOR INSERT
  TO authenticated
  WITH CHECK (user_id::text = auth.uid()::text);

CREATE POLICY "Users can update own visited topics"
  ON visited_topics FOR UPDATE
  TO authenticated
  USING (user_id::text = auth.uid()::text)
  WITH CHECK (user_id::text = auth.uid()::text);

CREATE POLICY "Users can delete own visited topics"
  ON visited_topics FOR DELETE
  TO authenticated
  USING (user_id::text = auth.uid()::text);

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  role text NOT NULL,
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own chat messages"
  ON chat_messages FOR SELECT
  TO authenticated
  USING (user_id::text = auth.uid()::text);

CREATE POLICY "Users can insert own chat messages"
  ON chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (user_id::text = auth.uid()::text);

CREATE POLICY "Users can update own chat messages"
  ON chat_messages FOR UPDATE
  TO authenticated
  USING (user_id::text = auth.uid()::text)
  WITH CHECK (user_id::text = auth.uid()::text);

CREATE POLICY "Users can delete own chat messages"
  ON chat_messages FOR DELETE
  TO authenticated
  USING (user_id::text = auth.uid()::text);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_topic_details_user_id ON topic_details(user_id);
CREATE INDEX IF NOT EXISTS idx_topic_details_topic_id ON topic_details(topic_id);
CREATE INDEX IF NOT EXISTS idx_visited_topics_user_id ON visited_topics(user_id);
CREATE INDEX IF NOT EXISTS idx_visited_topics_topic_id ON visited_topics(topic_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);