/**
 * Type definitions for Codex Remote Extension
 */

import * as vscode from "vscode";
import { CommandHandler } from "./command-handler";
import { WebSocketServer } from "./websocket-server";

export type AgentMode = "agent" | "ask" | "plan" | "debug" | "auto";
export type AIProvider = "codex";

export interface CommandMessage {
  id?: string;
  type: string;
  text?: string;
  terminal?: boolean | string;
  prompt?: boolean | string;
  execute?: boolean;
  command?: string;
  args?: any[];
  action?: string;
  clientId?: string;
  newSession?: boolean;
  sessionId?: string;
  relaySessionId?: string;
  limit?: number;
  agentMode?: AgentMode;
  senderDeviceId?: string;
  provider?: AIProvider; // backward-compatible field; codex only
}

export interface CommandResult {
  success: boolean;
  command_type?: string;
  message?: string;
  result?: any;
  error?: string;
  path?: string;
  data?: any;
}

export interface ChatResponseMessage {
  type: "chat_response";
  text: string;
  timestamp: string;
  source?: "extension" | "codex";
  sessionId?: string;
  clientId?: string;
}

export interface TerminalOutputMessage {
  type: "terminal_output";
  text: string;
  timestamp: string;
}

export interface UserMessage {
  type: "user_message";
  text: string;
  timestamp: string;
}

export type WebSocketMessage =
  | ChatResponseMessage
  | TerminalOutputMessage
  | UserMessage
  | CommandResult;

export interface ExtensionContext {
  outputChannel: vscode.OutputChannel;
  wsServer: WebSocketServer;
  commandHandler: CommandHandler;
  statusBarItem: vscode.StatusBarItem;
}
