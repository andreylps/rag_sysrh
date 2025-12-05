import React, { useState, useEffect, useRef } from "react";
import {
  Send,
  Paperclip,
  Bot,
  User,
  Loader2,
  AlertTriangle,
  RefreshCw,
  Menu,
  X,
} from "lucide-react";
import { API_BASE_URL, WS_BASE_URL } from "../config";

import ReactMarkdown from "react-markdown";
import ChatSidebar from "../components/ChatSidebar";

const TypingIndicator = () => (
  <div className="flex items-center gap-1 p-0 ml-2 mt-2 w-fit opacity-70">
    <div className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
    <div className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
    <div className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce"></div>
  </div>
);

const Chat = () => {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [connectionError, setConnectionError] = useState(null);
  const [selectedModel, setSelectedModel] = useState("openai");
  const [attachments, setAttachments] = useState([]);

  // Chat History State
  const [sessions, setSessions] = useState([]);
  const [currentSessionId, setCurrentSessionId] = useState(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const ws = useRef(null);
  const messagesEndRef = useRef(null);
  const fileInputRef = useRef(null);

  // --- Chat History Functions ---

  const fetchSessions = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/chat/sessions`);
      if (response.ok) {
        const data = await response.json();
        setSessions(data);
      }
    } catch (error) {
      console.error("Failed to fetch sessions:", error);
    }
  };

  const fetchSessionMessages = async (sessionId) => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/chat/sessions/${sessionId}/messages`
      );
      if (response.ok) {
        const data = await response.json();
        // Map DB messages to UI format
        const uiMessages = data.map((msg) => ({
          text: msg.content,
          sender: msg.sender,
          attachments: msg.attachments || [],
        }));
        setMessages(uiMessages);
      }
    } catch (error) {
      console.error("Failed to fetch messages:", error);
    }
  };

  const handleNewChat = () => {
    setMessages([]);
    setCurrentSessionId(null);
    setIsSidebarOpen(false);
    setInput("");
    setAttachments([]);
  };

  const handleSelectSession = (sessionId) => {
    setCurrentSessionId(sessionId);
    fetchSessionMessages(sessionId);
    setIsSidebarOpen(false);
  };

  const handleDeleteSession = async (sessionId) => {
    if (!window.confirm("Tem certeza que deseja excluir esta conversa?"))
      return;
    try {
      await fetch(`${API_BASE_URL}/chat/sessions/${sessionId}`, {
        method: "DELETE",
      });
      setSessions((prev) => prev.filter((s) => s.id !== sessionId));
      if (currentSessionId === sessionId) {
        handleNewChat();
      }
    } catch (error) {
      console.error("Failed to delete session:", error);
    }
  };

  // --- WebSocket & Effects ---

  useEffect(() => {
    fetchSessions();
    connectWebSocket();
    return () => {
      if (ws.current) {
        ws.current.close();
      }
    };
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages, isLoading]);

  const connectWebSocket = () => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) return;

    setIsConnected(false);
    setConnectionError(null);

    const wsUrl = `${WS_BASE_URL}/chat/ws`;

    try {
      console.log("Attempting WebSocket connection to 127.0.0.1...");
      ws.current = new WebSocket(wsUrl);

      ws.current.onopen = () => {
        console.log("WebSocket Connected");
        setIsConnected(true);
        setConnectionError(null);
      };

      ws.current.onmessage = (event) => {
        let message = event.data;

        // Tenta fazer o parse se for JSON
        try {
          const parsed = JSON.parse(message);
          if (parsed && parsed.text) {
            message = parsed.text;
          }
        } catch (e) {
          // Se não for JSON, usa a string original
        }

        // Ignore system messages
        if (message.startsWith("[SISTEMA]")) return;

        setMessages((prev) => [...prev, { text: message, sender: "ai" }]);
        setIsLoading(false);
        // Refresh sessions list to update timestamps/titles
        fetchSessions();
      };

      ws.current.onclose = () => {
        console.log("WebSocket Disconnected");
        setIsConnected(false);
        setConnectionError("Conexão perdida. Tentando reconectar...");
        setTimeout(connectWebSocket, 3000);
      };

      ws.current.onerror = (error) => {
        console.error("WebSocket Error:", error);
        setConnectionError("Erro na conexão com o servidor.");
        ws.current.close();
      };
    } catch (err) {
      console.error("Connection setup error:", err);
      setConnectionError("Falha ao iniciar conexão.");
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  const handleSendMessage = async () => {
    if ((!input.trim() && attachments.length === 0) || !isConnected) return;

    const userMessage = { text: input, sender: "user", attachments };
    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setAttachments([]);
    setIsLoading(true);

    // Prepare payload
    const payload = {
      text: userMessage.text,
      attachments: userMessage.attachments,
      model: selectedModel,
      sessionId: currentSessionId, // Send current session ID
    };

    try {
      ws.current.send(JSON.stringify(payload));
    } catch (error) {
      console.error("Send error:", error);
      setMessages((prev) => [
        ...prev,
        { text: "Erro ao enviar mensagem.", sender: "ai" },
      ]);
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  // --- File Handling ---
  const handleFileSelect = (e) => {
    const files = Array.from(e.target.files);

    files.forEach((file) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        setAttachments((prev) => [
          ...prev,
          {
            name: file.name,
            type: file.type,
            content: e.target.result, // Base64
          },
        ]);
      };
      reader.readAsDataURL(file);
    });
    e.target.value = null; // Reset input
  };

  const removeAttachment = (index) => {
    setAttachments((prev) => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="flex h-[calc(100vh-2rem)] gap-4">
      {/* Sidebar */}
      <ChatSidebar
        isOpen={isSidebarOpen}
        onClose={() => setIsSidebarOpen(false)}
        sessions={sessions}
        currentSessionId={currentSessionId}
        onSelectSession={handleSelectSession}
        onNewChat={handleNewChat}
        onDeleteSession={handleDeleteSession}
      />

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col h-full relative">
        {/* Mobile Toggle Button */}
        <button
          className="md:hidden absolute top-4 left-4 z-10 p-2 bg-slate-800 rounded-md text-white"
          onClick={() => setIsSidebarOpen(true)}
        >
          <Menu size={24} />
        </button>

        <header className="flex justify-between items-center mb-4 bg-transparent p-4">
          <div className="flex items-center gap-4 ml-10 md:ml-0">
            <h1 className="text-2xl font-medium text-slate-100 tracking-tight">
              neos
            </h1>

            {/* Online Status */}
            <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-800/50 rounded-full border border-slate-700/50">
              <span
                className={`w-2 h-2 rounded-full ${
                  isConnected
                    ? "bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]"
                    : "bg-red-500"
                }`}
              ></span>
              <span className="text-xs font-medium text-slate-300">
                {isConnected ? "Online" : "Offline"}
              </span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            {!isConnected && (
              <button
                onClick={connectWebSocket}
                className="text-xs text-red-400 hover:text-red-300 underline"
              >
                Reconectar
              </button>
            )}
          </div>
        </header>

        <div className="grow flex flex-col rounded-2xl bg-slate-950/50 overflow-hidden shadow-2xl border border-slate-800/30 relative">
          {/* Messages Area */}
          <div className="grow overflow-y-auto p-4 md:p-8 space-y-8 no-scrollbar scroll-smooth flex flex-col items-center">
            <div className="w-full max-w-3xl space-y-8">
              {messages.length === 0 && !connectionError && (
                <div className="h-full flex flex-col items-center justify-center text-slate-500 min-h-[400px]">
                  <div className="mb-8">
                    <h2 className="text-4xl font-medium text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-cyan-400">
                      Olá, Andrey
                    </h2>
                    <h3 className="text-4xl font-medium text-slate-500 mt-2">
                      Como posso ajudar hoje?
                    </h3>
                  </div>
                  <div className="w-full max-w-2xl grid grid-cols-1 md:grid-cols-3 gap-4">
                    <button
                      onClick={() =>
                        setInput("Criar uma imagem de um escritório futurista")
                      }
                      className="p-4 bg-[#1e1f20] hover:bg-[#2a2b2d] rounded-xl text-left transition-colors group border border-slate-800/50"
                    >
                      <span className="block text-slate-200 font-medium mb-1 group-hover:text-indigo-400 transition-colors">
                        Criar uma imagem
                      </span>
                      <span className="text-xs text-slate-500">
                        de um escritório futurista
                      </span>
                    </button>

                    <button
                      onClick={() =>
                        setInput(
                          "Planejar uma sprint com foco em débitos técnicos"
                        )
                      }
                      className="p-4 bg-[#1e1f20] hover:bg-[#2a2b2d] rounded-xl text-left transition-colors group border border-slate-800/50"
                    >
                      <span className="block text-slate-200 font-medium mb-1 group-hover:text-indigo-400 transition-colors">
                        Planejar uma sprint
                      </span>
                      <span className="text-xs text-slate-500">
                        com foco em débitos técnicos
                      </span>
                    </button>

                    <button
                      onClick={() =>
                        setInput("Analisar código em busca de vulnerabilidades")
                      }
                      className="p-4 bg-[#1e1f20] hover:bg-[#2a2b2d] rounded-xl text-left transition-colors group border border-slate-800/50"
                    >
                      <span className="block text-slate-200 font-medium mb-1 group-hover:text-indigo-400 transition-colors">
                        Analisar código
                      </span>
                      <span className="text-xs text-slate-500">
                        em busca de vulnerabilidades
                      </span>
                    </button>
                  </div>
                </div>
              )}

              {connectionError && (
                <div className="p-4 bg-red-900/20 border border-red-900/50 rounded-lg text-red-300 text-center text-sm mx-auto max-w-md mt-4">
                  {connectionError}
                </div>
              )}

              {messages.map((msg, index) => (
                <div
                  key={index}
                  className={`flex w-full ${
                    msg.sender === "user" ? "justify-end" : "justify-start"
                  }`}
                >
                  <div
                    className={`max-w-[85%] md:max-w-[75%] p-4 rounded-2xl ${
                      msg.sender === "user"
                        ? "bg-[#2a2a2a] text-slate-100 rounded-tr-sm"
                        : "bg-transparent text-slate-100 pl-0"
                    }`}
                  >
                    {msg.sender !== "user" && (
                      <div className="flex items-center gap-2 mb-3 text-indigo-400">
                        <div className="p-1 bg-indigo-500/10 rounded-lg">
                          <Bot size={16} />
                        </div>
                        <span className="text-sm font-medium text-slate-300">
                          neos
                        </span>
                      </div>
                    )}

                    <div className="prose prose-invert prose-sm md:prose-base max-w-none leading-relaxed text-slate-200">
                      <ReactMarkdown>{msg.text || ""}</ReactMarkdown>
                    </div>

                    {/* Attachments Display */}
                    {msg.attachments && msg.attachments.length > 0 && (
                      <div
                        className={`flex flex-wrap gap-2 mt-3 ${
                          msg.sender === "user"
                            ? "justify-end"
                            : "justify-start"
                        }`}
                      >
                        {msg.attachments.map((att, i) => (
                          <div
                            key={i}
                            className="flex items-center gap-2 bg-black/30 px-3 py-2 rounded-lg text-xs border border-white/10"
                          >
                            <Paperclip size={12} className="text-slate-400" />
                            <span className="truncate max-w-[150px] text-slate-300">
                              {att.name || "Anexo"}
                            </span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              ))}

              {/* Typing Indicator */}
              {isLoading && (
                <div className="flex justify-start">
                  <TypingIndicator />
                </div>
              )}

              <div ref={messagesEndRef} />
            </div>
          </div>

          {/* Input Area */}
          <div className="p-4 flex justify-center">
            <div className="w-full max-w-3xl">
              {/* Attachments Preview */}
              {attachments.length > 0 && (
                <div className="flex gap-2 mb-3 overflow-x-auto pb-2">
                  {attachments.map((att, i) => (
                    <div
                      key={i}
                      className="flex items-center gap-2 bg-slate-800 px-3 py-1.5 rounded-full text-xs text-slate-300 border border-slate-700"
                    >
                      <span className="truncate max-w-[100px]">{att.name}</span>
                      <button
                        onClick={() => removeAttachment(i)}
                        className="hover:text-red-400 transition-colors"
                      >
                        <X size={14} />
                      </button>
                    </div>
                  ))}
                </div>
              )}

              <div className="bg-[#1e1f20] rounded-[2rem] p-4 transition-colors shadow-lg">
                <textarea
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyPress={(e) => {
                    if (e.key === "Enter" && !e.shiftKey) {
                      e.preventDefault();
                      handleSendMessage();
                    }
                  }}
                  placeholder="Pergunte ao neos"
                  className="w-full bg-transparent text-slate-100 placeholder-slate-500 px-2 focus:outline-none resize-none min-h-[60px] scrollbar-hide text-base mb-2"
                  rows={1}
                  disabled={isLoading || !isConnected}
                  style={{ height: "auto", minHeight: "60px" }}
                />

                <div className="flex justify-between items-center">
                  {/* Model Selector (Left) */}
                  <div className="flex items-center gap-2 bg-[#2a2b2d] rounded-full px-3 py-1.5 border border-slate-700/30">
                    <span className="text-[10px] text-slate-400 font-medium mr-1">
                      Raciocínio
                    </span>
                    <select
                      value={selectedModel}
                      onChange={(e) => setSelectedModel(e.target.value)}
                      className="bg-transparent text-slate-300 text-xs font-medium focus:ring-0 outline-none border-none cursor-pointer hover:text-white appearance-none pr-4 relative z-10"
                      style={{ backgroundImage: "none" }}
                    >
                      <option
                        value="gemini"
                        className="bg-[#1e1f20] text-slate-300"
                      >
                        Gemini 1.5 Flash
                      </option>
                      <option
                        value="openai"
                        className="bg-[#1e1f20] text-slate-300"
                      >
                        GPT-4o
                      </option>
                    </select>
                  </div>

                  {/* Actions (Right) */}
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => fileInputRef.current?.click()}
                      className="p-2 text-slate-400 hover:text-indigo-400 hover:bg-slate-800/50 rounded-full transition-all"
                      title="Anexar arquivo"
                    >
                      <Paperclip size={20} />
                    </button>
                    <input
                      type="file"
                      multiple
                      ref={fileInputRef}
                      className="hidden"
                      onChange={handleFileSelect}
                    />

                    <button
                      onClick={handleSendMessage}
                      disabled={
                        isLoading ||
                        !isConnected ||
                        (!input.trim() && attachments.length === 0)
                      }
                      className={`p-2 rounded-full transition-all ${
                        isLoading || (!input.trim() && attachments.length === 0)
                          ? "text-slate-600 bg-transparent cursor-not-allowed"
                          : "text-white bg-indigo-600 hover:bg-indigo-500 shadow-lg shadow-indigo-500/20"
                      }`}
                    >
                      {isLoading ? (
                        <Loader2 className="animate-spin" size={20} />
                      ) : (
                        <Send size={20} />
                      )}
                    </button>
                  </div>
                </div>
              </div>

              <div className="flex justify-between items-center mt-3 px-2">
                {/* Model Selector in Footer */}

                <p className="text-[10px] text-slate-600">
                  neos pode cometer erros. Verifique as informações importantes.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Chat;
