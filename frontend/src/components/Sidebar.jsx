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
} from "lucide-react";
import "./Sidebar.css";

const Sidebar = ({ isAdmin, toggleAdmin }) => {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <Bot className="logo-icon" size={32} />
        <div className="logo-text">
          <span className="logo-title">NOESYS.AI</span>
          <span className="logo-subtitle">Agent Container</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        <div className="nav-section">
          <span className="nav-label">Módulos Ativos</span>

          <NavLink
            to="/"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <LayoutDashboard size={20} />
            <span>Governança & IA</span>
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
            <span>Documentação</span>
          </NavLink>

          {/* 2. Novo Link para o Backlog de Validação */}
          <NavLink
            to="/validacao"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <ClipboardCheck size={20} />
            <span>Validação (Analista)</span>
          </NavLink>
          {/* -------------------------------------- */}

          <NavLink
            to="/knowledge"
            className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
          >
            <BrainCircuit size={20} />
            <span>Base de Conhecimento</span>
          </NavLink>

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
