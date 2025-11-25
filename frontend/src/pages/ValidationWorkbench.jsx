// frontend/src/pages/ValidationWorkbench.jsx

import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { toast } from "react-toastify"; // Usaremos para notificações
import Select from "react-select"; // Vamos instalar para campos de seleção bonitos
import CreatableSelect from "react-select/creatable"; // Para RCMs que podem ser novas
import ReactMarkdown from "react-markdown";

const ValidationWorkbench = () => {
  const { issue_number } = useParams(); // Pega o número da issue da URL
  const navigate = useNavigate();

  // Estados para os detalhes da issue original (somente leitura)
  const [issueDetails, setIssueDetails] = useState(null);
  const [loadingIssue, setLoadingIssue] = useState(true);
  const [errorIssue, setErrorIssue] = useState(null);

  // Estados para os dados validados pelo analista (editáveis)
  const [tipoSolicitacao, setTipoSolicitacao] = useState("");
  const [prioridade, setPrioridade] = useState("");
  const [esforcoEstimado, setEsforcoEstimado] = useState("");
  const [rcmsRelacionadas, setRcmsRelacionadas] = useState([]); // Array de objetos { value, label }
  const [comentariosValidacao, setComentariosValidacao] = useState("");

  const [submitting, setSubmitting] = useState(false); // Estado para o botão de aprovação

  // Opções para os Selects (devem estar em sync com os Enums do backend)
  const tipoOptions = [
    { value: "Evolutiva", label: "Evolutiva" },
    { value: "Operação", label: "Operação" },
    { value: "Corretiva", label: "Corretiva" },
    { value: "Garantia", label: "Garantia" },
    { value: "Migração", label: "Migração" },
    { value: "Correção de dados", label: "Correção de dados" },
    {
      value: "Transferencia Conhecimento",
      label: "Transferência de Conhecimento",
    },
  ];

  // ... (rest of code)

  const prioridadeOptions = [
    { value: "Baixa", label: "Baixa" },
    { value: "Média", label: "Média" },
    { value: "Alta", label: "Alta" },
    { value: "Crítica", label: "Crítica" },
  ];

  // Função para buscar os detalhes da issue (mock ou do backend real)
  useEffect(() => {
    const fetchIssueDetails = async () => {
      setLoadingIssue(true);
      setErrorIssue(null);
      try {
        // --- BUSCA REAL DO BACKEND ---
        const response = await fetch(
          `http://localhost:8080/api/v1/validacao/issues/${issue_number}`
        );

        if (!response.ok) {
          if (response.status === 404) {
            throw new Error("Demanda não encontrada.");
          }
          throw new Error(`Erro ao carregar issue: ${response.status}`);
        }

        const issue = await response.json();
        setIssueDetails(issue);

        // Tenta pré-preencher com dados da descrição se a IA já tiver analisado
        // (Lógica simples de regex ou apenas defaults por enquanto)
        setTipoSolicitacao("Melhoria");
        setPrioridade("Média");
        setEsforcoEstimado("");
        setRcmsRelacionadas([]);
        setComentariosValidacao("");
      } catch (err) {
        console.error("Erro ao buscar detalhes da issue:", err);
        setErrorIssue("Não foi possível carregar os detalhes da demanda.");
      } finally {
        setLoadingIssue(false);
      }
    };

    fetchIssueDetails();
  }, [issue_number]);

  // Função para lidar com a submissão do formulário
  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setErrorIssue(null);

    const payload = {
      tipo_solicitacao: tipoSolicitacao,
      prioridade: prioridade,
      esforco_estimado: parseFloat(esforcoEstimado) || null, // Garante que seja float ou null
      rcms_relacionadas: rcmsRelacionadas.map((rcm) => rcm.value), // Extrai apenas os valores
      comentarios_validacao: comentariosValidacao,
    };

    try {
      const response = await fetch(
        `http://localhost:8080/api/v1/validacao/${issue_number}/approve`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        }
      );

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || `Erro API: ${response.status}`);
      }

      toast.success(`Demanda #${issue_number} validada com sucesso!`);
      navigate("/validacao"); // Volta para a tela de backlog após a validação
    } catch (err) {
      console.error("Erro ao aprovar validação:", err);
      toast.error(`Falha ao validar demanda: ${err.message}`);
      setErrorIssue(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  if (loadingIssue) {
    return (
      <div className="page-content flex justify-center items-center h-full">
        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-cyan-500"></div>
        <p className="ml-4 text-slate-400">Carregando demanda...</p>
      </div>
    );
  }

  if (errorIssue && !issueDetails) {
    // Mostrar erro se não conseguiu carregar a issue
    return (
      <div className="page-content card bg-red-900/20 border-red-900 text-red-400 p-6 text-center">
        <h3 className="font-bold text-lg mb-2">Erro</h3>
        <p>{errorIssue}</p>
        <button
          onClick={() => navigate("/validacao")}
          className="mt-4 underline hover:text-red-300"
        >
          Voltar para o Backlog
        </button>
      </div>
    );
  }

  if (!issueDetails) {
    // Caso a issue não seja encontrada (ex: URL inválida)
    return (
      <div className="page-content card bg-orange-900/20 border-orange-900 text-orange-400 p-6 text-center">
        <h3 className="font-bold text-lg mb-2">Demanda Não Encontrada</h3>
        <p>A demanda com o número #{issue_number} não foi localizada.</p>
        <button
          onClick={() => navigate("/validacao")}
          className="mt-4 underline hover:text-orange-300"
        >
          Voltar para o Backlog
        </button>
      </div>
    );
  }

  return (
    <div className="page-content flex flex-col h-full">
      <header className="page-header mb-6">
        <h1>
          ✨ Workbench de Validação{" "}
          <span className="text-cyan-400">#{issueDetails.number}</span>
        </h1>
        <p className="text-slate-400">
          Revise e aprove a análise da IA para a demanda selecionada.
        </p>
      </header>

      <form
        onSubmit={handleSubmit}
        className="flex-grow flex flex-col space-y-6"
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 flex-grow">
          {/* Coluna Esquerda: Detalhes da Demanda Original (Read-only) */}
          <div className="card bg-slate-800/50 p-6 flex flex-col h-full">
            <h2 className="text-xl font-semibold text-slate-200 mb-4">
              Demanda Original (GitHub)
            </h2>
            <div className="flex-grow overflow-y-auto pr-2">
              <h3 className="text-lg font-bold text-slate-300 mb-2">
                {issueDetails.title}
              </h3>
              <div className="text-slate-400 text-sm prose prose-invert max-w-none">
                <ReactMarkdown>
                  {issueDetails.body || "Sem descrição."}
                </ReactMarkdown>
              </div>
            </div>
            <div className="mt-4 pt-4 border-t border-slate-700">
              {/* Extração de Métricas da Análise da IA (se houver) */}
              {(() => {
                // Tenta encontrar o comentário da IA com as estimativas
                const aiComment = issueDetails.comments?.find((c) =>
                  c.body.includes("## 🤖 Análise Automática de Requisitos")
                );

                if (aiComment) {
                  // Regex simples para extrair os valores (ajuste conforme o formato exato do prompt)
                  const pfMatch = aiComment.body.match(
                    /\*\*Pontos de Função:\*\*\s*([\d\.]+)/
                  );
                  const prazoMatch = aiComment.body.match(
                    /\*\*Prazo Estimado:\*\*\s*(\d+)\s*dias/
                  );

                  const pf = pfMatch ? pfMatch[1] : "N/A";
                  const prazo = prazoMatch ? prazoMatch[1] : "N/A";

                  return (
                    <div className="grid grid-cols-2 gap-4 mb-4 bg-slate-900/50 p-3 rounded">
                      <div>
                        <span className="block text-xs text-slate-400 uppercase font-bold">
                          Pontos de Função
                        </span>
                        <span className="text-lg text-cyan-400 font-mono">
                          {pf}
                        </span>
                      </div>
                      <div>
                        <span className="block text-xs text-slate-400 uppercase font-bold">
                          Prazo (Dias Úteis)
                        </span>
                        <span className="text-lg text-cyan-400 font-mono">
                          {prazo}
                        </span>
                      </div>
                    </div>
                  );
                }
                return null;
              })()}

              <div className="text-sm text-right">
                <a
                  href={issueDetails.html_url}
                  target="_blank"
                  rel="noreferrer"
                  className="text-cyan-500 hover:underline"
                >
                  Abrir no GitHub &rarr;
                </a>
              </div>
            </div>
          </div>

          {/* Coluna Direita: Análise da IA para Validação (Editável) */}
          <div className="card p-6 flex flex-col h-full">
            <h2 className="text-xl font-semibold text-slate-200 mb-4">
              Análise da IA (Revisar e Ajustar)
            </h2>
            <div className="flex-grow overflow-y-auto pr-2 space-y-4">
              {" "}
              {/* Adicionado overflow e padding-right */}
              {/* Campo: Tipo de Solicitação */}
              <div>
                <label className="block text-slate-300 text-sm font-bold mb-2">
                  Tipo de Solicitação:
                </label>
                <Select
                  options={tipoOptions}
                  value={tipoOptions.find(
                    (opt) => opt.value === tipoSolicitacao
                  )}
                  onChange={(option) =>
                    setTipoSolicitacao(option ? option.value : "")
                  }
                  placeholder="Selecione o tipo..."
                  isClearable
                  classNamePrefix="react-select" // Para estilizar com Tailwind
                  styles={{
                    control: (baseStyles) => ({
                      ...baseStyles,
                      backgroundColor: "#1E293B", // bg-slate-800
                      borderColor: "#475569", // border-slate-600
                      color: "#E2E8F0", // text-slate-200
                    }),
                    singleValue: (baseStyles) => ({
                      ...baseStyles,
                      color: "#E2E8F0",
                    }),
                    input: (baseStyles) => ({
                      ...baseStyles,
                      color: "#E2E8F0",
                    }),
                    placeholder: (baseStyles) => ({
                      ...baseStyles,
                      color: "#94A3B8",
                    }), // text-slate-400
                    menu: (baseStyles) => ({
                      ...baseStyles,
                      backgroundColor: "#1E293B",
                      zIndex: 9999,
                    }),
                    option: (baseStyles, state) => ({
                      ...baseStyles,
                      backgroundColor: state.isFocused ? "#334155" : "#1E293B", // bg-slate-700 / bg-slate-800
                      color: state.isSelected ? "#06B6D4" : "#E2E8F0", // text-cyan-500 / text-slate-200
                      "&:active": {
                        backgroundColor: "#334155",
                      },
                    }),
                  }}
                />
              </div>
              {/* Campo: Prioridade */}
              <div>
                <label className="block text-slate-300 text-sm font-bold mb-2">
                  Prioridade Sugerida:
                </label>
                <Select
                  options={prioridadeOptions}
                  value={prioridadeOptions.find(
                    (opt) => opt.value === prioridade
                  )}
                  onChange={(option) =>
                    setPrioridade(option ? option.value : "")
                  }
                  placeholder="Selecione a prioridade..."
                  isClearable
                  classNamePrefix="react-select"
                  styles={{
                    control: (baseStyles) => ({
                      ...baseStyles,
                      backgroundColor: "#1E293B",
                      borderColor: "#475569",
                      color: "#E2E8F0",
                    }),
                    singleValue: (baseStyles) => ({
                      ...baseStyles,
                      color: "#E2E8F0",
                    }),
                    input: (baseStyles) => ({
                      ...baseStyles,
                      color: "#E2E8F0",
                    }),
                    placeholder: (baseStyles) => ({
                      ...baseStyles,
                      color: "#94A3B8",
                    }),
                    menu: (baseStyles) => ({
                      ...baseStyles,
                      backgroundColor: "#1E293B",
                      zIndex: 9999,
                    }),
                    option: (baseStyles, state) => ({
                      ...baseStyles,
                      backgroundColor: state.isFocused ? "#334155" : "#1E293B",
                      color: state.isSelected ? "#06B6D4" : "#E2E8F0",
                      "&:active": { backgroundColor: "#334155" },
                    }),
                  }}
                />
              </div>
              {/* Campo: Esforço Estimado */}
              <div>
                <label
                  htmlFor="esforco"
                  className="block text-slate-300 text-sm font-bold mb-2"
                >
                  Esforço Estimado (horas/PF):
                </label>
                <input
                  type="number"
                  id="esforco"
                  value={esforcoEstimado}
                  onChange={(e) => setEsforcoEstimado(e.target.value)}
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-slate-200 leading-tight focus:outline-none focus:shadow-outline bg-slate-800 border-slate-600 focus:border-cyan-500"
                  placeholder="Ex: 40.5"
                  step="0.5"
                />
              </div>
              {/* Campo: RCMs Relacionadas (Creatable Select) */}
              <div>
                <label className="block text-slate-300 text-sm font-bold mb-2">
                  RCMs Relacionadas:
                </label>
                <CreatableSelect
                  isMulti
                  options={[]} // Pode carregar opções pré-existentes do backend no futuro
                  value={rcmsRelacionadas}
                  onChange={(newValue) => setRcmsRelacionadas(newValue)}
                  placeholder="Adicione ou selecione RCMs..."
                  classNamePrefix="react-select"
                  styles={{
                    control: (baseStyles) => ({
                      ...baseStyles,
                      backgroundColor: "#1E293B",
                      borderColor: "#475569",
                      color: "#E2E8F0",
                    }),
                    multiValue: (baseStyles) => ({
                      ...baseStyles,
                      backgroundColor: "#334155",
                      color: "#E2E8F0",
                    }),
                    multiValueLabel: (baseStyles) => ({
                      ...baseStyles,
                      color: "#E2E8F0",
                    }),
                    multiValueRemove: (baseStyles) => ({
                      ...baseStyles,
                      color: "#94A3B8",
                      "&:hover": {
                        backgroundColor: "#475569",
                        color: "#E2E8F0",
                      },
                    }),
                    singleValue: (baseStyles) => ({
                      ...baseStyles,
                      color: "#E2E8F0",
                    }),
                    input: (baseStyles) => ({
                      ...baseStyles,
                      color: "#E2E8F0",
                    }),
                    placeholder: (baseStyles) => ({
                      ...baseStyles,
                      color: "#94A3B8",
                    }),
                    menu: (baseStyles) => ({
                      ...baseStyles,
                      backgroundColor: "#1E293B",
                      zIndex: 9999,
                    }),
                    option: (baseStyles, state) => ({
                      ...baseStyles,
                      backgroundColor: state.isFocused ? "#334155" : "#1E293B",
                      color: state.isSelected ? "#06B6D4" : "#E2E8F0",
                      "&:active": { backgroundColor: "#334155" },
                    }),
                  }}
                />
              </div>
              {/* Campo: Comentários de Validação */}
              <div>
                <label
                  htmlFor="comentarios"
                  className="block text-slate-300 text-sm font-bold mb-2"
                >
                  Comentários da Validação:
                </label>
                <textarea
                  id="comentarios"
                  rows="4"
                  value={comentariosValidacao}
                  onChange={(e) => setComentariosValidacao(e.target.value)}
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-slate-200 leading-tight focus:outline-none focus:shadow-outline bg-slate-800 border-slate-600 focus:border-cyan-500"
                  placeholder="Adicione observações ou justificativas para as alterações..."
                ></textarea>
              </div>
            </div>
          </div>
        </div>

        {/* Rodapé com Botões de Ação */}
        <div className="flex justify-end space-x-4 pt-4 border-t border-slate-800">
          <button
            type="button"
            onClick={() => navigate("/validacao")}
            className="bg-slate-700 hover:bg-slate-600 text-white font-bold py-2 px-6 rounded shadow transition-colors"
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={submitting}
            className={`bg-cyan-600 hover:bg-cyan-700 text-white font-bold py-2 px-6 rounded shadow transition-colors ${
              submitting ? "opacity-50 cursor-not-allowed" : ""
            }`}
          >
            {submitting ? "Aprovando..." : "Aprovar Validação"}
          </button>
        </div>
      </form>
    </div>
  );
};

export default ValidationWorkbench;
