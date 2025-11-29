// frontend/src/App.jsx

import { useState, useEffect, useRef } from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Sidebar from "./components/Sidebar";
import Governance from "./pages/Governance";
import Knowledge from "./pages/Knowledge";
import Dashboard from "./pages/Dashboard";
import Documentation from "./pages/Documentation";
import AdminDashboard from "./pages/AdminDashboard";
import LangSmith from "./pages/LangSmith";
import Welcome from "./pages/Welcome"; // <--- Novo Import
import "./App.css"; // Seus estilos globais
import DashboardWrapper from "./DashboardWrapper";
import TailwindWrapper from "./TailwindWrapper";
import { WS_BASE_URL } from "./config";

// --- IMPORTS PARA VALIDAÇÃO E NOTIFICAÇÕES ---
import ValidationBacklog from "./pages/ValidationBacklog";
import ValidationWorkbench from "./pages/ValidationWorkbench";
import ClientApproval from "./pages/ClientApproval";
import TechnicalWorkbench from "./pages/TechnicalWorkbench";
import QualityControlRoom from "./pages/QualityControlRoom"; // <--- NOVO IMPORT (Fase 6.1)
import ScrumRoom from "./pages/ScrumRoom"; // <--- NOVO IMPORT (Fase SM.3)
import DocumentationPage from "./pages/DocumentationPage"; // <--- NOVO IMPORT (Fase 6.8.2)
import Chat from "./pages/Chat";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css"; // Não se esqueça de importar o CSS!

// --- ÚNICA DEFINIÇÃO DA FUNÇÃO App ---
function App() {
  // Inicializa o estado lendo do localStorage
  const [isAdmin, setIsAdmin] = useState(() => {
    const saved = localStorage.getItem("isAdmin");
    return saved === "true";
  });
  const wsRef = useRef(null);

  const toggleAdmin = () => {
    const newState = !isAdmin;
    setIsAdmin(newState);
    localStorage.setItem("isAdmin", newState);
  };

  // --- GLOBAL WEBSOCKET FOR SYSTEM NOTIFICATIONS ---
  useEffect(() => {
    const connectWebSocket = () => {
      const wsUrl = `${WS_BASE_URL}/chat/ws`;
      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onopen = () => {
        console.log("Global System WebSocket Connected");
      };

      ws.onmessage = (event) => {
        const message = event.data;

        if (message.includes("[SISTEMA_START]")) {
          // Inicia notificação de carregamento
          toast.loading("Curva de Aprendizando sendo atualizada...", {
            toastId: "sys-update",
            position: "bottom-right",
            className: "text-[10px] font-medium", // Tamanho solicitado (pequeno)
            theme: "dark",
          });
        } else if (message.includes("[SISTEMA_END]")) {
          // Atualiza para sucesso e fecha
          toast.update("sys-update", {
            render: "Curva de Aprendizado Atualizada",
            type: "success",
            isLoading: false,
            autoClose: 3000,
            className: "text-[10px] font-medium",
          });
        }
      };

      ws.onclose = () => {
        console.log(
          "Global System WebSocket Disconnected. Reconnecting in 5s..."
        );
        setTimeout(connectWebSocket, 5000);
      };

      ws.onerror = (error) => {
        console.error("Global WebSocket Error:", error);
        ws.close();
      };
    };

    connectWebSocket();

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []);

  return (
    <Router>
      <div className="app-layout">
        <Sidebar isAdmin={isAdmin} toggleAdmin={toggleAdmin} />

        <main className="main-content">
          <Routes>
            <Route path="/" element={<Welcome />} />
            <Route path="/governance" element={<Governance />} />
            <Route path="/dashboard" element={<DashboardWrapper />} />
            <Route
              path="/docs"
              element={
                <TailwindWrapper>
                  <Documentation />
                </TailwindWrapper>
              }
            />
            <Route
              path="/chat"
              element={
                <TailwindWrapper>
                  <Chat />
                </TailwindWrapper>
              }
            />
            {/* --- ROTAS DE VALIDAÇÃO --- */}
            <Route
              path="/validacao"
              element={
                <TailwindWrapper>
                  <ValidationBacklog />
                </TailwindWrapper>
              }
            />
            <Route
              path="/validacao/:issue_number" // Rota com parâmetro para o Workbench
              element={
                <TailwindWrapper>
                  <ValidationWorkbench />
                </TailwindWrapper>
              }
            />
            <Route
              path="/cliente/aprovacao/:issue_number" // Rota do Cliente (Pública/Externa)
              element={
                <TailwindWrapper>
                  <ClientApproval />
                </TailwindWrapper>
              }
            />
            <Route
              path="/technical-review"
              element={
                <TailwindWrapper>
                  <TechnicalWorkbench />
                </TailwindWrapper>
              }
            />
            {/* --------------------------- */}

            {isAdmin && (
              <>
                <Route
                  path="/langsmith"
                  element={
                    <TailwindWrapper>
                      <LangSmith />
                    </TailwindWrapper>
                  }
                />
                <Route
                  path="/admin"
                  element={
                    <TailwindWrapper>
                      <AdminDashboard />
                    </TailwindWrapper>
                  }
                />
                <Route
                  path="/qa-room"
                  element={
                    <TailwindWrapper>
                      <QualityControlRoom />
                    </TailwindWrapper>
                  }
                />
                <Route
                  path="/scrum-room" // Fase SM.3
                  element={
                    <TailwindWrapper>
                      <ScrumRoom />
                    </TailwindWrapper>
                  }
                />
                <Route
                  path="/knowledge"
                  element={
                    <TailwindWrapper>
                      <Knowledge />
                    </TailwindWrapper>
                  }
                />
              </>
            )}

            <Route
              path="/documentation"
              element={
                <TailwindWrapper>
                  <DocumentationPage />
                </TailwindWrapper>
              }
            />
            {/* Rota Catch-All para 404 e Transições de Perfil */}
            <Route path="*" element={<Welcome />} />
          </Routes>

          <footer className="app-footer">
            <p>by noesys.ai</p>
          </footer>
          {/* <--- ToastContainer ADICIONADO AQUI, FORA DAS ROTAS, MAS DENTRO DA main --> */}
          <ToastContainer
            position="bottom-right"
            autoClose={5000}
            hideProgressBar={false}
            newestOnTop={false}
            closeOnClick
            rtl={false}
            pauseOnFocusLoss
            draggable
            pauseOnHover
            theme="dark"
          />
        </main>
      </div>
    </Router>
  );
}

export default App; // --- ÚNICA EXPORTAÇÃO PADRÃO ---
