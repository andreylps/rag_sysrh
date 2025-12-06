import React, { useEffect } from "react";
import { MessageSquare, Plus, Trash2, X } from "lucide-react";

const ChatSidebar = ({
  isOpen,
  onClose,
  sessions,
  currentSessionId,
  onSelectSession,
  onNewChat,
  onDeleteSession,
}) => {
  return (
    <div
      className={`fixed inset-y-0 left-0 z-50 w-56 bg-slate-900 border-r border-slate-800 transform transition-transform duration-300 ease-in-out ${
        isOpen ? "translate-x-0" : "-translate-x-full"
      } md:relative md:translate-x-0 md:w-56 md:flex md:flex-col`}
    >
      <div className="p-4 border-b border-slate-800 flex items-center justify-between">
        <h2 className="text-lg font-semibold text-slate-100">Histórico</h2>
        <button
          onClick={onClose}
          className="md:hidden text-slate-400 hover:text-white"
        >
          <X size={20} />
        </button>
      </div>

      <div className="p-4">
        <button
          onClick={onNewChat}
          className="w-full flex items-center justify-center gap-2 bg-purple-600/10 hover:bg-purple-600/20 text-purple-200 py-1.5 px-3 rounded-lg transition-colors border border-purple-500/20 text-sm"
        >
          <Plus size={16} />
          <span>Novo Chat</span>
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-2 space-y-2 no-scrollbar">
        {sessions.map((session) => (
          <div
            key={session.id}
            className={`group flex items-center justify-between p-3 rounded-lg cursor-pointer transition-colors ${
              currentSessionId === session.id
                ? "bg-slate-800 text-white"
                : "text-slate-400 hover:bg-slate-800/50 hover:text-slate-200"
            }`}
            onClick={() => onSelectSession(session.id)}
          >
            <div className="flex items-center gap-3 overflow-hidden">
              <MessageSquare size={16} className="shrink-0" />
              <span className="truncate text-sm font-medium">
                {session.title || "Novo Chat"}
              </span>
            </div>
            <button
              onClick={(e) => {
                e.stopPropagation();
                onDeleteSession(session.id);
              }}
              className="opacity-0 group-hover:opacity-100 p-1 text-slate-500 hover:text-red-400 transition-opacity"
              title="Excluir conversa"
            >
              <Trash2 size={14} />
            </button>
          </div>
        ))}

        {sessions.length === 0 && (
          <div className="text-center text-slate-600 text-sm mt-10">
            Nenhuma conversa salva.
          </div>
        )}
      </div>
    </div>
  );
};

export default ChatSidebar;
