// frontend/src/pages/Chat.jsx
import React, { useState, useEffect, useRef } from "react";
import { Send, Bot, User, AlertCircle, Loader2 } from "lucide-react";
import ReactMarkdown from "react-markdown";

const TypingIndicator = () => (
  <div className="flex gap-1 items-center p-2 h-6">
    <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
    <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
    <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce"></div>
  </div>
);

const Chat = () => {
  const [files, setFiles] = useState([]);
  const fileInputRef = useRef(null);

  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState("");
  const [isConnected, setIsConnected] = useState(false);
  const [isConnecting, setIsConnecting] = useState(true);
  const [connectionError, setConnectionError] = useState(null);
  const [isTyping, setIsTyping] = useState(false);
  const ws = useRef(null);
  const messagesEndRef = useRef(null);

  // Auto-scroll to bottom
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isTyping]);

  const handleFileSelect = (e) => {
    if (e.target.files) {
      setFiles((prev) => [...prev, ...Array.from(e.target.files)]);
    }
  };

  const removeFile = (index) => {
    setFiles((prev) => prev.filter((_, i) => i !== index));
  };

  const convertToBase64 = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => resolve(reader.result);
      reader.onerror = (error) => reject(error);
    });
  };

  useEffect(() => {
    // Connect to WebSocket
    const connectWebSocket = () => {
      setIsConnecting(true);
      setConnectionError(null);

      // Use the correct backend URL (adjust port if necessary, usually 8080)
      const wsUrl = "ws://localhost:8080/api/v1/chat/ws";

      try {
        ws.current = new WebSocket(wsUrl);

        ws.current.onopen = () => {
          console.log("WebSocket Connected");
          setIsConnected(true);
          setIsConnecting(false);
          setConnectionError(null);
        };

        ws.current.onmessage = (event) => {
          const message = event.data;

          // Ignore system messages (handled by App.jsx for toasts)
          if (message.startsWith("[SISTEMA]")) {
            return;
          }

          setIsTyping(false); // Stop typing when message is received
          setMessages((prev) => [...prev, { text: message, sender: "bot" }]);
        };

        ws.current.onclose = () => {
          console.log("WebSocket Disconnected");
          setIsConnected(false);
          setIsConnecting(false);
          // Optional: Attempt reconnect logic could go here
        };

        ws.current.onerror = (error) => {
          console.error("WebSocket Error:", error);
          setConnectionError("Erro na conexão com o servidor.");
          setIsConnecting(false);
          setIsTyping(false);
        };
      } catch (err) {
        setConnectionError("Falha ao iniciar conexão.");
        setIsConnecting(false);
        setIsTyping(false);
      }
    };

    connectWebSocket();

    return () => {
      if (ws.current) {
        ws.current.close();
      }
    };
  }, []);

  const handleSendMessage = async () => {
    if ((inputValue.trim() || files.length > 0) && isConnected) {
      // Prepare attachments
      const attachments = await Promise.all(
        files.map(async (file) => ({
          name: file.name,
          type: file.type,
          content: await convertToBase64(file),
        }))
      );

      // Add user message to UI
      const userMessage = {
        text: inputValue,
        sender: "user",
        attachments: attachments.map((a) => ({ name: a.name, type: a.type })), // Don't store full base64 in UI state if not needed, or store for preview
      };
      setMessages((prev) => [...prev, userMessage]);
      setIsTyping(true);

      // Send to backend as JSON
      const payload = JSON.stringify({
        text: inputValue,
        attachments: attachments,
      });
      ws.current.send(payload);

      // Clear input
      setInputValue("");
      setFiles([]);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === "Enter") {
      handleSendMessage();
    }
  };

  return (
    <div className="page-content flex flex-col h-full bg-slate-900 text-slate-200 p-6">
      <header className="flex items-center justify-between mb-6 border-b border-slate-700 pb-4">
        <h1 className="text-2xl font-semibold text-slate-100 flex items-center gap-3">
          <Bot className="text-cyan-400" size={28} />
          Assistente Inteligente
        </h1>
        <div className="flex items-center gap-2">
          {isConnecting ? (
            <span className="flex items-center gap-2 text-yellow-500 text-xs uppercase tracking-wider font-medium">
              <Loader2 className="animate-spin" size={14} /> Conectando
            </span>
          ) : isConnected ? (
            <span className="flex items-center gap-2 text-emerald-400 text-xs uppercase tracking-wider font-medium">
              <span className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse"></span>{" "}
              Online
            </span>
          ) : (
            <span className="flex items-center gap-2 text-red-400 text-xs uppercase tracking-wider font-medium">
              <AlertCircle size={14} /> Offline
            </span>
          )}
        </div>
      </header>

      <div className="flex-grow flex flex-col rounded-xl bg-slate-950/50 overflow-hidden shadow-2xl border border-slate-800">
        {/* Messages Area */}
        <div className="flex-grow overflow-y-auto p-6 space-y-6 custom-scrollbar">
          {messages.length === 0 && !connectionError && (
            <div className="h-full flex flex-col items-center justify-center text-slate-500 opacity-60">
              <Bot size={64} className="mb-4 text-slate-600" />
              <p className="text-lg font-light">Como posso ajudar você hoje?</p>
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
                    ? "bg-cyan-600 text-white rounded-tr-sm"
                    : "bg-slate-800 text-slate-200 rounded-tl-sm border border-slate-700"
                }`}
              >
                <div className="flex gap-3 w-full">
                  <div className="flex-shrink-0 mt-1">
                    {msg.sender === "user" ? (
                      <User size={20} className="opacity-80" />
                    ) : (
                      <Bot size={20} className="text-cyan-400" />
                    )}
                  </div>
                  <div
                    className={`flex-grow min-w-0 ${
                      msg.sender === "user" ? "text-right" : "text-left"
                    }`}
                  >
                    {/* Attachments Display */}
                    {msg.attachments && msg.attachments.length > 0 && (
                      <div
                        className={`flex flex-wrap gap-2 mb-2 ${
                          msg.sender === "user"
                            ? "justify-end"
                            : "justify-start"
                        }`}
                      >
                        {msg.attachments.map((att, i) => (
                          <div
                            key={i}
                            className="flex items-center gap-1 bg-black/20 px-2 py-1 rounded text-xs"
                          >
                            <span className="truncate max-w-[150px]">
                              {att.name}
                            </span>
                          </div>
                        ))}
                      </div>
                    )}

                    {msg.sender === "user" ? (
                      <p className="whitespace-pre-wrap m-0 text-left">
                        {msg.text}
                      </p>
                    ) : (
                      <div
                        className="prose prose-invert prose-sm max-w-none 
                        prose-headings:font-semibold prose-headings:text-slate-100 prose-headings:mb-2 prose-headings:mt-4
                        prose-h1:text-xl prose-h2:text-lg prose-h3:text-base
                        prose-p:text-slate-300 prose-p:leading-relaxed prose-p:mb-3
                        prose-strong:text-cyan-400
                        prose-ul:list-disc prose-ul:pl-4 prose-ul:mb-3
                        prose-ol:list-decimal prose-ol:pl-4 prose-ol:mb-3
                        prose-li:text-slate-300 prose-li:mb-1
                        prose-code:text-cyan-300 prose-code:bg-slate-900/50 prose-code:px-1 prose-code:py-0.5 prose-code:rounded prose-code:before:content-none prose-code:after:content-none
                        prose-pre:bg-slate-950 prose-pre:border prose-pre:border-slate-800 prose-pre:rounded-lg
                        prose-blockquote:border-l-4 prose-blockquote:border-cyan-500 prose-blockquote:pl-4 prose-blockquote:italic prose-blockquote:text-slate-400
                        text-left"
                      >
                        <ReactMarkdown>{msg.text}</ReactMarkdown>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}

          {isTyping && (
            <div className="flex justify-start">
              <div className="bg-slate-800 p-3 rounded-2xl rounded-tl-sm border border-slate-700">
                <TypingIndicator />
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* Input Area */}
        <div className="p-4 bg-slate-900 border-t border-slate-800">
          {/* File Previews */}
          {files.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-3">
              {files.map((file, index) => (
                <div
                  key={index}
                  className="relative group bg-slate-800 border border-slate-700 rounded-lg p-2 flex items-center gap-2"
                >
                  <div className="text-xs text-slate-300 truncate max-w-[150px]">
                    {file.name}
                  </div>
                  <button
                    onClick={() => removeFile(index)}
                    className="text-slate-500 hover:text-red-400 transition-colors"
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          )}

          <div className="flex gap-3 max-w-4xl mx-auto">
            <button
              onClick={() => fileInputRef.current?.click()}
              className="p-4 rounded-xl bg-slate-800 border border-slate-700 text-slate-400 hover:text-cyan-400 hover:border-cyan-500 transition-all"
              title="Anexar arquivo"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48" />
              </svg>
            </button>
            <input
              type="file"
              ref={fileInputRef}
              onChange={handleFileSelect}
              className="hidden"
              multiple
            />

            <input
              type="text"
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyPress={handleKeyPress}
              disabled={!isConnected}
              placeholder={
                isConnected ? "Digite sua mensagem..." : "Conectando..."
              }
              className="flex-grow p-4 rounded-xl bg-slate-800 border border-slate-700 text-slate-200 placeholder-slate-500 focus:outline-none focus:border-cyan-500 focus:ring-1 focus:ring-cyan-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-inner"
            />
            <button
              onClick={handleSendMessage}
              disabled={
                !isConnected || (!inputValue.trim() && files.length === 0)
              }
              className="bg-cyan-600 hover:bg-cyan-500 disabled:bg-slate-700 disabled:text-slate-500 disabled:cursor-not-allowed text-white p-4 rounded-xl transition-all shadow-lg hover:shadow-cyan-900/20 flex items-center justify-center"
            >
              <Send size={20} />
            </button>
          </div>
          <div className="text-center mt-2">
            <p className="text-[10px] text-slate-600">
              O assistente pode cometer erros. Verifique informações
              importantes.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Chat;
