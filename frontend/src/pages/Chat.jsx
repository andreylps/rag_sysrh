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
import ReactMarkdown from "react-markdown";
import ChatSidebar from "../components/ChatSidebar";

const TypingIndicator = () => (
  <div className="flex items-center gap-1 p-4 bg-slate-800 rounded-2xl rounded-tl-sm border border-slate-700 w-fit">
    <div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
    <div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
    <div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce"></div>
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
      const response = await fetch(
        "http://127.0.0.1:8080/api/v1/chat/sessions"
      );
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
        `http://127.0.0.1:8080/api/v1/chat/sessions/${sessionId}/messages`
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
      await fetch(`http://127.0.0.1:8080/api/v1/chat/sessions/${sessionId}`, {
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

    const wsUrl = "ws://127.0.0.1:8080/api/v1/chat/ws";

    try {
      console.log("Attempting WebSocket connection to 127.0.0.1...");
      ws.current = new WebSocket(wsUrl);

      ws.current.onopen = () => {
        console.log("WebSocket Connected");
        setIsConnected(true);
        setConnectionError(null);
      };

      ws.current.onmessage = (event) => {
        const message = event.data;

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

        <header className="flex justify-between items-center mb-4 bg-slate-900/50 p-4 rounded-xl border border-slate-800 backdrop-blur-sm">
          <div className="flex items-center gap-3 ml-10 md:ml-0">
            {" "}
            {/* Added margin for mobile button */}
            <div className="p-2 bg-indigo-500/20 rounded-lg">
              <Bot className="text-indigo-400" size={24} />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-100">
                Assistente RAG SYS-RH
              </h1>
              <div className="flex items-center gap-2">
                <span
                  className={`w-2 h-2 rounded-full ${
                    isConnected ? "bg-green-500" : "bg-red-500"
                  }`}
                ></span>
                <span className="text-xs text-slate-400">
                  {isConnected ? "Online" : "Offline"}
                </span>
                {!isConnected && (
                  <button
                    onClick={connectWebSocket}
                    className="ml-2 text-xs text-indigo-400 hover:text-indigo-300 flex items-center gap-1"
                  >
                    <RefreshCw size={10} /> Retry
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Model Selector */}
          <div className="flex items-center gap-2">
            <span className="text-sm text-slate-400 hidden sm:inline">
              Modelo:
            </span>
            <select
              value={selectedModel}
              onChange={(e) => setSelectedModel(e.target.value)}
              className="bg-slate-800 text-slate-200 text-sm rounded-lg border border-slate-700 p-2 focus:ring-2 focus:ring-indigo-500 outline-none"
            >
              <option value="gemini">Gemini 1.5 Flash</option>
              <option value="openai">GPT-4 Turbo</option>
            </select>
          </div>
        </header>

        <div className="flex-grow flex flex-col rounded-xl bg-slate-950/50 overflow-hidden shadow-2xl border border-slate-800">
          {/* Messages Area */}
          <div className="flex-grow overflow-y-auto p-6 space-y-6 no-scrollbar">
            {messages.length === 0 && !connectionError && (
              <div className="h-full flex flex-col items-center justify-center text-slate-500 opacity-60">
                <Bot size={64} className="mb-4 text-slate-600" />
                <p className="text-lg font-light">
                  Como posso ajudar você hoje?
                </p>
              </div>
            )}

            {connectionError && (
              <div className="p-4 bg-red-900/20 border border-red-900/50 rounded-lg text-red-300 text-center text-sm">
                {connectionError}
              </div>
            )}

            {messages.map((msg, index) => (
              <div
                key={index}
                className={`flex ${
                  msg.sender === "user" ? "justify-end" : "justify-start"
                }`}
              >
                <div
                  className={`max-w-[85%] p-4 rounded-2xl shadow-sm ${
                    msg.sender === "user"
                      ? "bg-purple-600/10 text-white rounded-tr-sm border border-purple-500/30"
                      : "bg-slate-800 text-slate-200 rounded-tl-sm border border-slate-700"
                  }`}
                >
                  <div className="flex items-center gap-2 mb-1 opacity-70">
                    {msg.sender === "user" ? (
                      <User size={14} />
                    ) : (
                      <Bot size={14} />
                    )}
                    <span className="text-xs font-medium uppercase tracking-wider">
                      {msg.sender === "user" ? "Você" : "Assistente"}
                    </span>
                  </div>
                  <div className="prose prose-invert prose-sm max-w-none">
                    <ReactMarkdown>{msg.text || ""}</ReactMarkdown>
                  </div>
                  {/* Attachments Display */}
                  {msg.attachments && msg.attachments.length > 0 && (
                    <div
                      className={`flex flex-wrap gap-2 mt-2 ${
                        msg.sender === "user" ? "justify-end" : "justify-start"
                      }`}
                    >
                      {msg.attachments.map((att, i) => (
                        <div
                          key={i}
                          className="flex items-center gap-1 bg-black/20 px-2 py-1 rounded text-xs"
                        >
                          <Paperclip size={10} />
                          <span className="truncate max-w-[150px]">
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

          {/* Input Area */}
          <div className="p-4 bg-slate-900/80 border-t border-slate-800">
            {/* Attachments Preview */}
            {attachments.length > 0 && (
              <div className="flex gap-2 mb-2 overflow-x-auto pb-2">
                {attachments.map((att, i) => (
                  <div
                    key={i}
                    className="flex items-center gap-2 bg-slate-800 px-3 py-1 rounded-full text-xs text-slate-300 border border-slate-700"
                  >
                    <span className="truncate max-w-[100px]">{att.name}</span>
                    <button
                      onClick={() => removeAttachment(i)}
                      className="hover:text-red-400"
                    >
                      <X size={12} />
                    </button>
                  </div>
                ))}
              </div>
            )}

            <div className="flex gap-2">
              <button
                onClick={() => fileInputRef.current?.click()}
                className="p-3 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-colors"
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

              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Digite sua mensagem..."
                className="flex-grow bg-purple-600/5 text-white placeholder-slate-400 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-purple-500/50 border border-purple-500/20"
                disabled={isLoading || !isConnected}
              />
              <button
                onClick={handleSendMessage}
                disabled={
                  isLoading ||
                  !isConnected ||
                  (!input.trim() && attachments.length === 0)
                }
                className="p-3 bg-purple-600/20 text-purple-200 rounded-xl hover:bg-purple-600/30 disabled:opacity-50 disabled:cursor-not-allowed transition-all border border-purple-500/30"
              >
                {isLoading ? (
                  <Loader2 className="animate-spin" size={20} />
                ) : (
                  <Send size={20} />
                )}
              </button>
            </div>
            <div className="text-center mt-2">
              <p className="text-[10px] text-slate-600">
                RAG SYS-RH pode cometer erros. Verifique as informações
                importantes.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Chat;
