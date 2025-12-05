import React, { useState } from "react";
import {
  Lightbulb,
  Download,
  Loader2,
  CheckCircle,
  FileText,
  Save,
  Edit3,
} from "lucide-react";
import { API_BASE_URL } from "../config";

const POCGenerator = () => {
  const [formData, setFormData] = useState({
    problema_contexto: "",
    objetivo_principal: "",
    funcionalidades_desejadas: "",
    kpis_sucesso: "",
    prazo_restricoes: "",
  });
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  // State for editing content
  const [editableContent, setEditableContent] = useState(null);
  const [isUpdating, setIsUpdating] = useState(false);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleEditChange = (field, value) => {
    setEditableContent({ ...editableContent, [field]: value });
  };

  const handleArrayEditChange = (field, index, value) => {
    const newArray = [...editableContent[field]];
    newArray[index] = value;
    setEditableContent({ ...editableContent, [field]: newArray });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setResult(null);
    setEditableContent(null);

    try {
      const response = await fetch(`${API_BASE_URL}/poc/generate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      if (!response.ok) throw new Error("Falha ao gerar proposta");

      const data = await response.json();
      setResult(data);
      setEditableContent(data.content_preview); // Initialize editable content
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateDocument = async () => {
    setIsUpdating(true);
    try {
      const response = await fetch(`${API_BASE_URL}/poc/update-document`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(editableContent),
      });

      if (!response.ok) throw new Error("Falha ao atualizar documento");

      const data = await response.json();
      setResult((prev) => ({ ...prev, filename: data.filename }));
      alert("Documento atualizado com sucesso!");
    } catch (err) {
      alert("Erro ao atualizar documento: " + err.message);
    } finally {
      setIsUpdating(false);
    }
  };

  const handleDownload = () => {
    if (result?.filename) {
      window.open(`${API_BASE_URL}/poc/download/${result.filename}`, "_blank");
    }
  };

  return (
    <div className="p-8 max-w-6xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-100 flex items-center gap-3">
          <Lightbulb className="text-yellow-400" size={32} />
          Gerador de Proposta de POC
        </h1>
        <p className="text-slate-400 mt-2">
          Descreva a necessidade do cliente e nossa IA criará uma proposta
          técnica completa.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Form Panel */}
        <div className="space-y-6">
          <div className="bg-slate-900/50 p-6 rounded-xl border border-slate-800">
            <h2 className="text-xl font-semibold text-white mb-4 flex items-center gap-2">
              <Edit3 size={20} className="text-blue-400" /> Dados de Entrada
            </h2>
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Contexto e Problema
                </label>
                <textarea
                  name="problema_contexto"
                  value={formData.problema_contexto}
                  onChange={handleChange}
                  required
                  rows={4}
                  className="w-full bg-slate-950 border border-slate-700 rounded-lg p-3 text-slate-200 focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                  placeholder="Descreva o cenário atual e as dores do cliente..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Objetivo Principal
                </label>
                <input
                  type="text"
                  name="objetivo_principal"
                  value={formData.objetivo_principal}
                  onChange={handleChange}
                  required
                  className="w-full bg-slate-950 border border-slate-700 rounded-lg p-3 text-slate-200 focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                  placeholder="O que se espera alcançar com a POC?"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Funcionalidades Desejadas
                </label>
                <textarea
                  name="funcionalidades_desejadas"
                  value={formData.funcionalidades_desejadas}
                  onChange={handleChange}
                  required
                  rows={3}
                  className="w-full bg-slate-950 border border-slate-700 rounded-lg p-3 text-slate-200 focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                  placeholder="Liste as principais features..."
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    KPIs de Sucesso
                  </label>
                  <input
                    type="text"
                    name="kpis_sucesso"
                    value={formData.kpis_sucesso}
                    onChange={handleChange}
                    required
                    className="w-full bg-slate-950 border border-slate-700 rounded-lg p-3 text-slate-200 focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                    placeholder="Ex: Redução de 30% no tempo..."
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Prazo / Restrições (Opcional)
                  </label>
                  <input
                    type="text"
                    name="prazo_restricoes"
                    value={formData.prazo_restricoes}
                    onChange={handleChange}
                    className="w-full bg-slate-950 border border-slate-700 rounded-lg p-3 text-slate-200 focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                    placeholder="Ex: 2 semanas, orçamento limitado..."
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-3 rounded-lg transition-colors flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <>
                    <Loader2 className="animate-spin" size={20} />
                    Gerando Proposta...
                  </>
                ) : (
                  <>
                    <Lightbulb size={20} />
                    Gerar Proposta de POC
                  </>
                )}
              </button>
            </form>
          </div>
        </div>

        {/* Results & Editing Panel */}
        <div className="space-y-6">
          {result && editableContent ? (
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 animate-fade-in flex flex-col h-full">
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3 text-emerald-400">
                  <CheckCircle size={28} />
                  <h3 className="text-xl font-bold">Proposta Gerada</h3>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={handleUpdateDocument}
                    disabled={isUpdating}
                    className="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 transition-colors disabled:opacity-50"
                  >
                    {isUpdating ? (
                      <Loader2 className="animate-spin" size={16} />
                    ) : (
                      <Save size={16} />
                    )}
                    Atualizar DOCX
                  </button>
                  <button
                    onClick={handleDownload}
                    className="bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 transition-colors"
                  >
                    <Download size={16} />
                    Baixar
                  </button>
                </div>
              </div>

              <div className="space-y-4 overflow-y-auto max-h-[600px] pr-2 custom-scrollbar">
                {/* Editable Fields */}
                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-500 uppercase">
                    Título da Proposta
                  </label>
                  <input
                    type="text"
                    value={editableContent.titulo}
                    onChange={(e) => handleEditChange("titulo", e.target.value)}
                    className="w-full bg-slate-950 border border-slate-700 rounded p-2 text-slate-200 text-lg font-semibold"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-500 uppercase">
                    Resumo Executivo
                  </label>
                  <textarea
                    value={editableContent.resumo_executivo}
                    onChange={(e) =>
                      handleEditChange("resumo_executivo", e.target.value)
                    }
                    rows={5}
                    className="w-full bg-slate-950 border border-slate-700 rounded p-2 text-slate-300 text-sm"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-500 uppercase">
                    Escopo Técnico
                  </label>
                  {editableContent.escopo_tecnico?.map((item, index) => (
                    <div key={index} className="flex gap-2">
                      <span className="text-slate-500 mt-2">•</span>
                      <textarea
                        value={item}
                        onChange={(e) =>
                          handleArrayEditChange(
                            "escopo_tecnico",
                            index,
                            e.target.value
                          )
                        }
                        rows={2}
                        className="w-full bg-slate-950 border border-slate-700 rounded p-2 text-slate-300 text-sm"
                      />
                    </div>
                  ))}
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-500 uppercase">
                    Arquitetura Sugerida
                  </label>
                  <textarea
                    value={editableContent.arquitetura_sugerida}
                    onChange={(e) =>
                      handleEditChange("arquitetura_sugerida", e.target.value)
                    }
                    rows={3}
                    className="w-full bg-slate-950 border border-slate-700 rounded p-2 text-slate-300 text-sm"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-500 uppercase">
                    KPIs de Sucesso
                  </label>
                  {editableContent.kpis_sucesso?.map((item, index) => (
                    <div key={index} className="flex gap-2">
                      <span className="text-slate-500 mt-2">•</span>
                      <input
                        type="text"
                        value={item}
                        onChange={(e) =>
                          handleArrayEditChange(
                            "kpis_sucesso",
                            index,
                            e.target.value
                          )
                        }
                        className="w-full bg-slate-950 border border-slate-700 rounded p-2 text-slate-300 text-sm"
                      />
                    </div>
                  ))}
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-500 uppercase">
                    Cronograma Estimado
                  </label>
                  <textarea
                    value={editableContent.cronograma_estimado}
                    onChange={(e) =>
                      handleEditChange("cronograma_estimado", e.target.value)
                    }
                    rows={2}
                    className="w-full bg-slate-950 border border-slate-700 rounded p-2 text-slate-300 text-sm"
                  />
                </div>
              </div>
            </div>
          ) : (
            <div className="bg-slate-900/30 border border-slate-800 rounded-xl p-6 text-center h-full flex flex-col items-center justify-center text-slate-500 min-h-[400px]">
              <FileText size={48} className="mb-4 opacity-50" />
              <p>
                Preencha o formulário ao lado para gerar uma nova proposta.
                <br />
                Você poderá editar o conteúdo antes de baixar.
              </p>
            </div>
          )}

          {error && (
            <div className="bg-red-900/20 border border-red-500/30 rounded-xl p-4 text-red-300 text-sm flex items-center gap-2">
              <span className="font-bold">Erro:</span> {error}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default POCGenerator;
