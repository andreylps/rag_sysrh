import React, { useState, useEffect } from "react";
import Editor from "@monaco-editor/react";
import { FileCode, AlertCircle } from "lucide-react";

const CodeReviewViewer = ({ issueId }) => {
  const [files, setFiles] = useState([]);
  const [selectedFile, setSelectedFile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchReviewFiles = async () => {
      setLoading(true);
      setError(null);
      try {
        const response = await fetch(
          `http://localhost:8080/api/v1/review/${issueId}/files`
        );

        if (!response.ok) {
          if (response.status === 404) {
            throw new Error(
              "Nenhum relatório de mudanças encontrado para esta demanda."
            );
          }
          throw new Error("Falha ao carregar arquivos para revisão.");
        }

        const data = await response.json();
        setFiles(data);

        // Seleciona o primeiro arquivo por padrão se houver
        if (data.length > 0) {
          setSelectedFile(data[0]);
        }
      } catch (err) {
        console.error(err);
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    if (issueId) {
      fetchReviewFiles();
    }
  }, [issueId]);

  const getLanguageFromExtension = (filename) => {
    if (!filename) return "plaintext";
    const ext = filename.split(".").pop().toLowerCase();
    switch (ext) {
      case "py":
        return "python";
      case "js":
        return "javascript";
      case "jsx":
        return "javascript";
      case "ts":
        return "typescript";
      case "tsx":
        return "typescript";
      case "json":
        return "json";
      case "html":
        return "html";
      case "css":
        return "css";
      case "sql":
        return "sql";
      case "md":
        return "markdown";
      default:
        return "plaintext";
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-cyan-500"></div>
        <span className="ml-3 text-slate-400">Carregando arquivos...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-900/20 border border-red-900 text-red-400 p-6 rounded-lg flex items-center">
        <AlertCircle className="mr-3" size={24} />
        <div>
          <h3 className="font-bold">Erro ao carregar revisão</h3>
          <p>{error}</p>
        </div>
      </div>
    );
  }

  if (files.length === 0) {
    return (
      <div className="text-center p-10 text-slate-500 bg-slate-800/50 rounded-lg border border-slate-700">
        <p>Nenhum arquivo modificado encontrado neste relatório.</p>
      </div>
    );
  }

  return (
    <div className="flex h-[600px] border border-slate-700 rounded-lg overflow-hidden bg-slate-900">
      {/* Sidebar: Lista de Arquivos */}
      <div className="w-1/4 border-r border-slate-700 bg-slate-800/50 flex flex-col">
        <div className="p-3 border-b border-slate-700 bg-slate-800">
          <h3 className="font-bold text-slate-300 text-sm uppercase tracking-wider">
            Arquivos ({files.length})
          </h3>
        </div>
        <div className="flex-grow overflow-y-auto">
          <ul className="divide-y divide-slate-700/50">
            {files.map((file) => (
              <li key={file.path}>
                <button
                  onClick={() => setSelectedFile(file)}
                  className={`w-full text-left p-3 text-sm flex items-center transition-colors ${
                    selectedFile?.path === file.path
                      ? "bg-cyan-900/30 text-cyan-400 border-l-2 border-cyan-500"
                      : "text-slate-400 hover:bg-slate-700/50 hover:text-slate-200"
                  }`}
                >
                  <FileCode size={16} className="mr-2 flex-shrink-0" />
                  <span className="truncate" title={file.path}>
                    {file.path}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </div>
      </div>

      {/* Main: Editor de Código */}
      <div className="w-3/4 flex flex-col bg-[#1e1e1e]">
        {selectedFile ? (
          <>
            <div className="p-2 border-b border-slate-700 bg-slate-800 flex justify-between items-center">
              <span className="text-sm font-mono text-slate-300 px-2">
                {selectedFile.path}
              </span>
              <span className="text-xs text-slate-500 uppercase">
                {selectedFile.status === "ok"
                  ? "Leitura OK"
                  : "Erro de Leitura"}
              </span>
            </div>
            <div className="flex-grow relative">
              {selectedFile.status === "ok" ? (
                <Editor
                  height="100%"
                  defaultLanguage={getLanguageFromExtension(selectedFile.path)}
                  language={getLanguageFromExtension(selectedFile.path)}
                  value={selectedFile.content}
                  theme="vs-dark"
                  options={{
                    readOnly: true,
                    minimap: { enabled: false },
                    scrollBeyondLastLine: false,
                    fontSize: 14,
                    renderWhitespace: "selection",
                  }}
                />
              ) : (
                <div className="p-6 text-red-400 font-mono text-sm">
                  {selectedFile.content}
                </div>
              )}
            </div>
          </>
        ) : (
          <div className="flex-grow flex items-center justify-center text-slate-500">
            <p>Selecione um arquivo para visualizar o código.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default CodeReviewViewer;
