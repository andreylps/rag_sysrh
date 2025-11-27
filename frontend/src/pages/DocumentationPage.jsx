import React, { useState, useEffect } from "react";
import axios from "axios";
import {
  BookOpen,
  Search,
  Download,
  FileText,
  Loader,
  File,
  FileSpreadsheet,
  FileCode,
  Info,
  X,
  Folder,
  ChevronLeft,
  Home,
} from "lucide-react";

const DocumentationPage = () => {
  const [activeTab, setActiveTab] = useState("all"); // 'all' or 'search'
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Search State
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState([]);
  const [searching, setSearching] = useState(false);

  // Summary State
  const [summary, setSummary] = useState(null);
  const [summarizingDocPath, setSummarizingDocPath] = useState(null);
  const [summaryLoading, setSummaryLoading] = useState(false);

  // Pagination State
  const [visibleCount, setVisibleCount] = useState(50);

  // Navigation State
  const [currentPath, setCurrentPath] = useState("");

  useEffect(() => {
    fetchDocuments(currentPath);
  }, [currentPath]);

  const fetchDocuments = async (path = "") => {
    setLoading(true);
    try {
      const response = await axios.get(
        `http://localhost:8080/api/v1/documentation/list?path=${encodeURIComponent(
          path
        )}`
      );
      setDocuments(response.data);
    } catch (err) {
      console.error("Erro ao buscar documentos:", err);
      setError("Falha ao carregar a lista de documentos.");
    } finally {
      setLoading(false);
    }
  };

  const handleFolderClick = (folderName) => {
    const newPath = currentPath ? `${currentPath}/${folderName}` : folderName;
    setCurrentPath(newPath);
    setVisibleCount(50); // Reset pagination
  };

  const handleBackClick = () => {
    if (!currentPath) return;
    const parts = currentPath.split("/");
    parts.pop();
    setCurrentPath(parts.join("/"));
    setVisibleCount(50);
  };

  const handleHomeClick = () => {
    setCurrentPath("");
    setVisibleCount(50);
  };

  const handleSearch = async (e) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;

    setSearching(true);
    try {
      const response = await axios.get(
        `http://localhost:8080/api/v1/documentation/search?query=${encodeURIComponent(
          searchQuery
        )}`
      );
      setSearchResults(response.data);
    } catch (err) {
      console.error("Erro na busca:", err);
      // Fallback ou toast de erro
    } finally {
      setSearching(false);
    }
  };

  const handleDownload = async (filePath, fileName) => {
    try {
      const response = await axios.get(
        `http://localhost:8080/api/v1/documentation/download?file_path=${encodeURIComponent(
          filePath
        )}`,
        { responseType: "blob" }
      );
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", fileName);
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (err) {
      console.error("Erro no download:", err);
      alert("Erro ao baixar o arquivo.");
    }
  };

  const handleSummarize = async (filePath) => {
    setSummarizingDocPath(filePath);
    setSummaryLoading(true);
    setSummary(null); // Limpa resumo anterior
    try {
      const response = await axios.get(
        `http://localhost:8080/api/v1/documentation/summarize?file_path=${encodeURIComponent(
          filePath
        )}`
      );
      setSummary(response.data.summary);
    } catch (err) {
      console.error("Erro ao resumir:", err);
      setSummary("Não foi possível gerar o resumo deste documento.");
    } finally {
      setSummaryLoading(false);
    }
  };

  const handlePrint = (filePath) => {
    // Abre o arquivo em uma nova aba para impressão (o navegador gerencia PDF/Imagem/Texto)
    // Para DOCX/XLSX, o navegador fará download, o que é o comportamento esperado se não houver conversor.
    const url = `http://localhost:8080/api/v1/documentation/download?file_path=${encodeURIComponent(
      filePath
    )}`;
    window.open(url, "_blank");
  };

  const getFileIcon = (type) => {
    if (type.includes("RCM")) return <FileCode className="text-blue-400" />;
    if (type.includes("Memória"))
      return <FileSpreadsheet className="text-emerald-400" />;
    if (type.includes("Manual"))
      return <BookOpen className="text-purple-400" />;
    return <FileText className="text-slate-400" />;
  };

  const renderDocumentRow = (doc) => {
    if (doc.type === "folder") {
      return (
        <div
          key={doc.path}
          onClick={() => handleFolderClick(doc.name)}
          className="bg-slate-800/50 p-4 rounded-lg border border-slate-700 hover:border-indigo-500 hover:bg-slate-800 transition-all cursor-pointer flex items-center gap-4 group"
        >
          <div className="p-2 bg-indigo-500/10 rounded-lg group-hover:bg-indigo-500/20 transition-colors">
            <Folder className="text-indigo-400" size={24} />
          </div>
          <div>
            <h3 className="font-semibold text-slate-200 group-hover:text-indigo-300 transition-colors">
              {doc.name}
            </h3>
            <p className="text-xs text-slate-500">Pasta de arquivos</p>
          </div>
        </div>
      );
    }

    return (
      <div
        key={doc.path}
        className="bg-slate-800/50 p-4 rounded-lg border border-slate-700 hover:border-indigo-500/50 transition-all flex flex-col gap-4"
      >
        <div className="flex justify-between items-start">
          <div className="flex items-start gap-3">
            <div className="mt-1">{getFileIcon(doc.type)}</div>
            <div>
              <h3 className="font-semibold text-slate-200">{doc.name}</h3>
              <div className="flex gap-2 text-xs mt-1">
                <span className="bg-slate-700 text-slate-300 px-2 py-0.5 rounded">
                  {doc.type}
                </span>
                <span className="text-slate-500">
                  {new Date(doc.last_modified).toLocaleDateString()}
                </span>
              </div>
            </div>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => handlePrint(doc.path)}
              className="p-2 hover:bg-slate-700 rounded-lg text-slate-400 hover:text-blue-400 transition-colors"
              title="Imprimir / Visualizar"
            >
              <BookOpen size={18} />
            </button>
            <button
              onClick={() => handleSummarize(doc.path)}
              className="p-2 hover:bg-slate-700 rounded-lg text-slate-400 hover:text-indigo-400 transition-colors"
              title="Ver Resumo (IA)"
            >
              <Info size={18} />
            </button>
            <button
              onClick={() => handleDownload(doc.path, doc.name)}
              className="p-2 hover:bg-slate-700 rounded-lg text-slate-400 hover:text-emerald-400 transition-colors"
              title="Baixar"
            >
              <Download size={18} />
            </button>
          </div>
        </div>

        {/* Área de Resumo Expansível */}
        {summarizingDocPath === doc.path && (
          <div className="bg-slate-900/80 p-4 rounded border border-indigo-500/30 animate-in fade-in slide-in-from-top-2">
            <div className="flex justify-between items-center mb-2">
              <h4 className="text-sm font-bold text-indigo-400 flex items-center gap-2">
                <BookOpen size={14} /> Resumo Inteligente
              </h4>
              <button
                onClick={() => {
                  setSummarizingDocPath(null);
                  setSummary(null);
                }}
                className="text-slate-500 hover:text-slate-300"
              >
                <X size={14} />
              </button>
            </div>
            {summaryLoading ? (
              <div className="flex items-center gap-2 text-slate-400 text-sm py-2">
                <Loader className="animate-spin" size={14} />
                Lendo e resumindo documento...
              </div>
            ) : (
              <p className="text-slate-300 text-sm leading-relaxed whitespace-pre-wrap">
                {summary}
              </p>
            )}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="p-8 max-w-7xl mx-auto animate-fade-in">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-white flex items-center gap-3">
          <BookOpen className="text-indigo-500" size={32} />
          Biblioteca de Documentação
        </h1>
        <p className="text-slate-400 mt-2">
          Central de conhecimento do projeto. Acesse manuais, RCMs e guias
          técnicos.
        </p>
      </header>

      {/* Tabs */}
      <div className="flex gap-4 mb-6 border-b border-slate-700">
        <button
          onClick={() => setActiveTab("all")}
          className={`pb-3 px-4 font-medium transition-colors relative ${
            activeTab === "all"
              ? "text-indigo-400 border-b-2 border-indigo-500"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Estante
        </button>
        <button
          onClick={() => setActiveTab("search")}
          className={`pb-3 px-4 font-medium transition-colors relative ${
            activeTab === "search"
              ? "text-indigo-400 border-b-2 border-indigo-500"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Busca Inteligente
        </button>
      </div>

      {/* Conteúdo da Aba: Estante */}
      {activeTab === "all" && (
        <div className="space-y-4">
          {/* Breadcrumbs / Navigation */}
          <div className="flex items-center gap-2 mb-4 text-sm text-slate-400">
            <button
              onClick={handleHomeClick}
              className="hover:text-indigo-400 flex items-center gap-1 transition-colors"
            >
              <Home size={16} /> Início
            </button>
            {currentPath && (
              <>
                <span className="text-slate-600">/</span>
                <button
                  onClick={handleBackClick}
                  className="hover:text-indigo-400 flex items-center gap-1 transition-colors"
                >
                  <ChevronLeft size={16} /> Voltar
                </button>
                <span className="text-slate-600">/</span>
                <span className="text-slate-200 font-medium">
                  {currentPath.split("/").pop()}
                </span>
              </>
            )}
          </div>
          {loading ? (
            <div className="flex justify-center py-12">
              <Loader className="animate-spin text-indigo-500" size={32} />
            </div>
          ) : error ? (
            <div className="text-red-400 bg-red-900/20 p-4 rounded border border-red-900/50">
              {error}
            </div>
          ) : documents.length === 0 ? (
            <div className="text-center py-12 text-slate-500">
              Nenhum documento encontrado.
            </div>
          ) : (
            <>
              <div className="grid grid-cols-1 gap-4">
                {documents
                  .slice(0, visibleCount)
                  .map((doc) => renderDocumentRow(doc))}
              </div>
              {visibleCount < documents.length && (
                <div className="flex justify-center mt-6">
                  <button
                    onClick={() => setVisibleCount((prev) => prev + 50)}
                    className="bg-slate-700 hover:bg-slate-600 text-white px-6 py-2 rounded-lg transition-colors"
                  >
                    Carregar Mais ({documents.length - visibleCount} restantes)
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      )}

      {/* Conteúdo da Aba: Busca Inteligente */}
      {activeTab === "search" && (
        <div className="space-y-6">
          <form onSubmit={handleSearch} className="relative">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Faça uma pergunta ou digite palavras-chave (ex: 'Como calcular ponto de função?')"
              className="w-full bg-slate-800 border border-slate-700 rounded-xl p-4 pl-12 text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
            />
            <Search
              className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500"
              size={20}
            />
            <button
              type="submit"
              disabled={searching || !searchQuery.trim()}
              className="absolute right-2 top-1/2 -translate-y-1/2 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {searching ? "Buscando..." : "Buscar"}
            </button>
          </form>

          <div className="space-y-4">
            {searching ? (
              <div className="flex justify-center py-8">
                <Loader className="animate-spin text-indigo-500" size={24} />
              </div>
            ) : searchResults.length > 0 ? (
              <div className="grid grid-cols-1 gap-4 animate-in fade-in slide-in-from-bottom-4">
                <h3 className="text-slate-400 text-sm font-medium mb-2">
                  Resultados encontrados: {searchResults.length}
                </h3>
                {searchResults.map((doc) => renderDocumentRow(doc))}
              </div>
            ) : searchQuery && !searching ? (
              <div className="text-center py-8 text-slate-500">
                Nenhum documento encontrado para sua busca.
              </div>
            ) : (
              <div className="text-center py-12 text-slate-600">
                <BookOpen size={48} className="mx-auto mb-4 opacity-20" />
                <p>
                  O Agente Bibliotecário está pronto para ajudar. Digite sua
                  dúvida acima.
                </p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default DocumentationPage;
