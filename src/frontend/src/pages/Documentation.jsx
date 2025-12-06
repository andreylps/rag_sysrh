import React, { useState } from "react";
import { API_BASE_URL } from "../config";

const Documentation = () => {
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [formData, setFormData] = useState({
    titulo: "Solicitação Exemplo",
    descricao: "Descrição técnica da mudança...",
    itens: [
      {
        nome: "Manter Usuário",
        tipo: "ALI",
        der: 19,
        rlr: 1,
        justificativa: "Teste",
      },
    ],
  });

  const handleGenerate = async () => {
    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const response = await fetch(
        `${API_BASE_URL}/documents/generate`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(formData),
        }
      );

      if (!response.ok) {
        const errData = await response.json();
        throw new Error(errData.detail || "Erro na geração de documentos");
      }

      const data = await response.json();
      setResult(data);
    } catch (err) {
      console.error(err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = async (path, filename) => {
    try {
      // Codifica o path para passar na URL query string
      const encodedPath = encodeURIComponent(path);
      const url = `${API_BASE_URL}/documents/download?path=${encodedPath}`;

      // Abre em nova aba para iniciar download
      window.open(url, "_blank");
    } catch (err) {
      console.error(err);
      alert("Erro ao iniciar download");
    }
  };

  return (
    <div className="p-6 space-y-6 bg-slate-950 min-h-screen text-slate-200">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-slate-100">
          Geração de Documentos
        </h1>
        <p className="text-slate-400">
          Gere RCMs e Memórias de Cálculo automaticamente.
        </p>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Formulário de Entrada */}
        <div className="bg-slate-900 p-6 rounded-lg shadow-lg border border-slate-800">
          <h2 className="text-xl font-semibold mb-4 text-cyan-400">
            Dados da Solicitação
          </h2>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-400">
                Título
              </label>
              <input
                type="text"
                className="mt-1 block w-full rounded-md border-slate-700 bg-slate-800 text-slate-200 shadow-sm focus:border-cyan-500 focus:ring-cyan-500 sm:text-sm p-2 border"
                value={formData.titulo}
                onChange={(e) =>
                  setFormData({ ...formData, titulo: e.target.value })
                }
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400">
                Descrição Técnica
              </label>
              <textarea
                className="mt-1 block w-full rounded-md border-slate-700 bg-slate-800 text-slate-200 shadow-sm focus:border-cyan-500 focus:ring-cyan-500 sm:text-sm p-2 border"
                rows="4"
                value={formData.descricao}
                onChange={(e) =>
                  setFormData({ ...formData, descricao: e.target.value })
                }
              />
            </div>

            <div className="bg-slate-800 p-4 rounded border border-slate-700">
              <h3 className="text-sm font-medium text-slate-300 mb-2">
                Item Funcional (Exemplo)
              </h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs text-slate-500">Nome</label>
                  <input
                    type="text"
                    className="w-full text-sm border-slate-600 bg-slate-700 text-slate-200 rounded p-1"
                    value={formData.itens[0].nome}
                    onChange={(e) => {
                      const newItens = [...formData.itens];
                      newItens[0].nome = e.target.value;
                      setFormData({ ...formData, itens: newItens });
                    }}
                  />
                </div>
                <div>
                  <label className="block text-xs text-slate-500">
                    Tipo (ALI, EE, etc)
                  </label>
                  <select
                    className="w-full text-sm border-slate-600 bg-slate-700 text-slate-200 rounded p-1"
                    value={formData.itens[0].tipo}
                    onChange={(e) => {
                      const newItens = [...formData.itens];
                      newItens[0].tipo = e.target.value;
                      setFormData({ ...formData, itens: newItens });
                    }}
                  >
                    <option value="ALI">ALI</option>
                    <option value="AIE">AIE</option>
                    <option value="EE">EE</option>
                    <option value="SE">SE</option>
                    <option value="CE">CE</option>
                  </select>
                </div>
              </div>
            </div>

            <button
              onClick={handleGenerate}
              disabled={loading}
              className={`w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white ${
                loading ? "bg-slate-600" : "bg-cyan-600 hover:bg-cyan-700"
              } focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-cyan-500 transition-colors`}
            >
              {loading ? "Gerando..." : "Gerar Documentos"}
            </button>
          </div>
        </div>

        {/* Área de Resultados */}
        <div className="bg-slate-900 p-6 rounded-lg shadow-lg border border-slate-800">
          <h2 className="text-xl font-semibold mb-4 text-cyan-400">
            Arquivos Gerados
          </h2>

          {error && (
            <div className="bg-red-900/30 border-l-4 border-red-500 p-4 mb-4">
              <p className="text-red-400">{error}</p>
            </div>
          )}

          {!result && !loading && !error && (
            <div className="text-center py-12 text-slate-600">
              <p>
                Preencha os dados e clique em gerar para ver os arquivos aqui.
              </p>
            </div>
          )}

          {result && (
            <div className="space-y-4 animate-fade-in">
              <div className="bg-green-900/30 border-l-4 border-green-500 p-4">
                <p className="text-green-400 font-medium">{result.message}</p>
              </div>

              <div className="space-y-3">
                {result.rcm_filename && (
                  <div className="flex items-center justify-between p-4 bg-slate-800 rounded-lg border border-slate-700">
                    <div className="flex items-center">
                      <svg
                        className="h-8 w-8 text-blue-400 mr-3"
                        fill="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                        <polyline points="14 2 14 8 20 8"></polyline>
                        <line x1="16" y1="13" x2="8" y2="13"></line>
                        <line x1="16" y1="17" x2="8" y2="17"></line>
                        <polyline points="10 9 9 9 8 9"></polyline>
                      </svg>
                      <div>
                        <p className="font-medium text-slate-200">
                          Relatório de Controle de Mudança (RCM)
                        </p>
                        <p className="text-xs text-slate-500">Formato .docx</p>
                      </div>
                    </div>
                    <button
                      onClick={() =>
                        handleDownload(result.rcm_filename, "RCM.docx")
                      }
                      className="px-3 py-1 bg-slate-700 border border-slate-600 rounded-md text-sm font-medium text-slate-200 hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-cyan-500 transition-colors"
                    >
                      Baixar
                    </button>
                  </div>
                )}

                {result.memoria_filename && (
                  <div className="flex items-center justify-between p-4 bg-slate-800 rounded-lg border border-slate-700">
                    <div className="flex items-center">
                      <svg
                        className="h-8 w-8 text-green-400 mr-3"
                        fill="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                        <polyline points="14 2 14 8 20 8"></polyline>
                        <line x1="16" y1="13" x2="8" y2="13"></line>
                        <line x1="16" y1="17" x2="8" y2="17"></line>
                        <polyline points="10 9 9 9 8 9"></polyline>
                      </svg>
                      <div>
                        <p className="font-medium text-slate-200">
                          Memória de Cálculo SISP
                        </p>
                        <p className="text-xs text-slate-500">Formato .xlsx</p>
                      </div>
                    </div>
                    <button
                      onClick={() =>
                        handleDownload(
                          result.memoria_filename,
                          "MemoriaCalculo.xlsx"
                        )
                      }
                      className="px-3 py-1 bg-slate-700 border border-slate-600 rounded-md text-sm font-medium text-slate-200 hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-cyan-500 transition-colors"
                    >
                      Baixar
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Documentation;
