import { useState } from "react";
import axios from "axios";

// --- OPÇÕES ATUALIZADAS ---
// Nova lista de tipos de solicitação conforme solicitado.
const TIPOS_SOLICITACAO = {
  EVOLUTIVA: "Evolutiva",
  CORRETIVA: "Corretiva",
  OPERACAO: "Operação",
  GARANTIA: "Garantia",
  MIGRACAO: "Migração",
  TRANSF_CONHECIMENTO: "Transferência de Conhecimento",
  CORRECAO_DADOS: "Correção de Dados",
};

const PRIORIDADES_SUGERIDAS = {
  BAIXA: "Baixa",
  MEDIA: "Média",
  ALTA: "Alta",
};

const Governance = () => {
  const [titulo, setTitulo] = useState("");
  const [descricao, setDescricao] = useState("");

  // Atualizado o valor inicial para um que exista na nova lista (ex: EVOLUTIVA)
  const [tipoSolicitacao, setTipoSolicitacao] = useState(
    TIPOS_SOLICITACAO.EVOLUTIVA
  );
  const [prioridadeSugerida, setPrioridadeSugerida] = useState(
    PRIORIDADES_SUGERIDAS.MEDIA
  );

  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const response = await axios.post(
        "http://localhost:8080/api/v1/solicitacoes/",
        {
          titulo,
          descricao,
          // O backend precisa ser atualizado para aceitar estes novos valores!
          tipo_solicitacao: tipoSolicitacao,
          prioridade_sugerida: prioridadeSugerida,
        }
      );
      setResult(response.data);
      // Limpa o formulário após o envio bem-sucedido e reseta para os padrões
      setTitulo("");
      setDescricao("");
      setTipoSolicitacao(TIPOS_SOLICITACAO.EVOLUTIVA);
      setPrioridadeSugerida(PRIORIDADES_SUGERIDAS.MEDIA);
    } catch (err) {
      console.error(err);
      // Tenta extrair a mensagem de erro de validação do backend (útil se o Enum não bater)
      const errorMsg =
        err.response?.data?.detail ||
        "Falha ao enviar solicitação. Verifique se o backend está rodando e se os tipos de solicitação estão alinhados.";
      setError(errorMsg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="page-content">
      <header className="page-header">
        <h1>🚀 RAG SYS-RH</h1>
        <p>noesys.ai - Portal de Governança e Inteligencia Artificial</p>
      </header>

      <div className="card form-card">
        <h2>Nova Solicitação</h2>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="titulo">Título</label>
            <input
              id="titulo"
              type="text"
              value={titulo}
              onChange={(e) => setTitulo(e.target.value)}
              placeholder="Resumo do problema ou pedido..."
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group col">
              {/* Label atualizada aqui */}
              <label htmlFor="tipoSolicitacao">Tipo de Solicitação</label>
              <select
                id="tipoSolicitacao"
                value={tipoSolicitacao}
                onChange={(e) => setTipoSolicitacao(e.target.value)}
                required
              >
                {/* Mapeia as novas opções do objeto atualizado */}
                {Object.values(TIPOS_SOLICITACAO).map((option) => (
                  <option key={option} value={option}>
                    {option}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group col">
              <label htmlFor="prioridadeSugerida">Prioridade Sugerida</label>
              <select
                id="prioridadeSugerida"
                value={prioridadeSugerida}
                onChange={(e) => setPrioridadeSugerida(e.target.value)}
                required
              >
                {Object.values(PRIORIDADES_SUGERIDAS).map((option) => (
                  <option key={option} value={option}>
                    {option}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="descricao">Descrição Detalhada</label>
            <textarea
              id="descricao"
              value={descricao}
              onChange={(e) => setDescricao(e.target.value)}
              placeholder="Descreva o cenário, o erro ou a necessidade..."
              rows="6"
              required
            />
          </div>

          <button type="submit" disabled={loading} className="submit-btn">
            {loading ? (
              <span className="loader">Processando...</span>
            ) : (
              "Enviar Solicitação"
            )}
          </button>
        </form>
      </div>

      {result && (
        <div className="result-card success">
          <h3>✅ Solicitação Recebida!</h3>
          <p>{result.mensagem}</p>
          <div className="issue-info">
            <strong>Issue #{result.issue_id}</strong>
            <a
              href={result.link_issue}
              target="_blank"
              rel="noreferrer"
              className="issue-link"
            >
              Acompanhar no GitHub &rarr;
            </a>
          </div>
        </div>
      )}

      {error && (
        <div className="result-card error">
          <p>❌ {error}</p>
        </div>
      )}
    </div>
  );
};

export default Governance;
