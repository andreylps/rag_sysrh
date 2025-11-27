import React from "react";
import { NavLink } from "react-router-dom";
import {
  LayoutDashboard,
  FileText,
  BrainCircuit,
  BarChart3,
  ShieldAlert,
  Bot,
  Settings,
  // 1. Novo ícone importado para a validação
  ClipboardCheck,
  MessageSquare,
  Activity,
  Code,
  ShieldCheck, // <--- Novo ícone (Fase 6.1)
  BookOpen, // <--- Novo ícone (Fase 6.8.2)
  Mail, // <--- Novo ícone para Central de Solicitações
} from "lucide-react";
import "./Sidebar.css";

const Sidebar = ({ isAdmin, toggleAdmin }) => {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <NavLink
          to="/"
          className="flex items-center gap-3 hover:opacity-80 transition-opacity"
        >
          <Bot className="logo-icon" size={32} />
          <div className="logo-text">
            <span className="logo-title">NOESYS.AI</span>
            <span className="logo-subtitle">Agent Container</span>
          </div>
        </NavLink>
      </div>

      <nav className="sidebar-nav">
        <div className="nav-section">
          <span className="nav-label">Módulos Ativos</span>

          <NavLink
            to="/governance"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <Mail
              size={20}
              className="logo-icon"
              style={{ width: "20px", height: "20px" }}
            />
            <span>Central de Solicitações</span>
          </NavLink>

          <NavLink
            to="/dashboard"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <BarChart3 size={20} />
            <span>BI & Analytics</span>
          </NavLink>

          <NavLink
            to="/docs"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <FileText size={20} />
            <span>Documentação (Legado)</span>
          </NavLink>

          <NavLink
            to="/documentation"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <BookOpen size={20} />
            <span>Biblioteca</span>
          </NavLink>

          {/* 2. Novo Link para o Backlog de Validação */}
          <NavLink
            to="/validacao"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <ClipboardCheck size={20} />
            <span>Validação (Analista)</span>
          </NavLink>

          <NavLink
            to="/technical-review"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <Code size={20} />
            <span>Revisão Técnica</span>
          </NavLink>
          {/* -------------------------------------- */}

          <NavLink
            to="/chat"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <MessageSquare size={20} />
            <span>Chat Corporativo</span>
          </NavLink>
        </div>

        {isAdmin && (
          <div className="nav-section admin-section">
            <span className="nav-label">Administração</span>
            <NavLink
              to="/admin"
              className={({ isActive }) =>
                `nav-item admin-item ${isActive ? "active" : ""}`
              }
            >
              <Activity size={20} />
              <span>Painel do Maestro</span>
            </NavLink>
            <NavLink
              to="/langsmith"
              className={({ isActive }) =>
                `nav-item admin-item ${isActive ? "active" : ""}`
              }
            >
              <ShieldAlert size={20} />
              <span>Observabilidade</span>
            </NavLink>
            <NavLink
              to="/qa-room"
              className={({ isActive }) =>
                `nav-item admin-item ${isActive ? "active" : ""}`
              }
            >
              <ShieldCheck size={20} />
              <span>Sala de Qualidade</span>
            </NavLink>
            <NavLink
              to="/knowledge"
              className={({ isActive }) =>
                `nav-item admin-item ${isActive ? "active" : ""}`
              }
            >
              <BrainCircuit size={20} />
              <span>Base de Conhecimento</span>
            </NavLink>
          </div>
        )}
      </nav>

      <div className="sidebar-footer">
        <button className="user-profile" onClick={toggleAdmin}>
          <div className="avatar">
            <Settings size={18} />
          </div>
          <div className="user-info">
            <span className="user-name">Admin User</span>
            <span className="user-role">
              {isAdmin ? "Administrator" : "Viewer"}
            </span>
          </div>
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
