import React from "react";

export const Dashboard = () => (
  <div className="page-content">
    <header className="page-header">
      <h1>📊 BI & Analytics</h1>
      <p>Dashboard de Indicadores e Métricas</p>
    </header>
    <div className="card">
      <div className="placeholder-content">
        <h3>🚧 Em Construção</h3>
        <p>O Agente de BI está sendo migrado para esta interface.</p>
      </div>
    </div>
  </div>
);

export const Docs = () => (
  <div className="page-content">
    <header className="page-header">
      <h1>📝 Documentação</h1>
      <p>Gerador de RCM e Memórias de Cálculo</p>
    </header>
    <div className="card">
      <div className="placeholder-content">
        <h3>🚧 Em Construção</h3>
        <p>O Gerador de Documentos será integrado aqui em breve.</p>
      </div>
    </div>
  </div>
);

export const Knowledge = () => (
  <div className="page-content">
    <header className="page-header">
      <h1>🧠 Base de Conhecimento</h1>
      <p>Gestão de Manuais e Regras de Negócio</p>
    </header>
    <div className="card">
      <div className="placeholder-content">
        <h3>🚧 Em Construção</h3>
        <p>A interface de gestão da base vetorial está em desenvolvimento.</p>
      </div>
    </div>
  </div>
);

export const LangSmith = () => (
  <div className="page-content">
    <header className="page-header">
      <h1>🛠️ Observabilidade</h1>
      <p>LangSmith Tracing & Monitoramento</p>
    </header>
    <div className="card full-height">
      <iframe
        src="https://smith.langchain.com/"
        title="LangSmith"
        style={{
          width: "100%",
          height: "600px",
          border: "none",
          borderRadius: "8px",
        }}
      />
    </div>
  </div>
);
