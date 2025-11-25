import React, { useState, useEffect } from "react";

const Knowledge = () => {
  const [documents, setDocuments] = useState([]);
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState("");

  // --- ESTADO DE ADMINISTRAÇÃO (SIMULADO) ---
  // Em produção, isso viria do seu contexto de usuário/autenticação global.
  // Use este checkbox na tela para testar a funcionalidade.
  const [isAdmin, setIsAdmin] = useState(false);

  // Estados para Sincronização
  const [showSyncModal, setShowSyncModal] = useState(false);
  const [availableManuals, setAvailableManuals] = useState([]);
  const [selectedManuals, setSelectedManuals] = useState([]);
  const [syncing, setSyncing] = useState(false);

  useEffect(() => {
    fetchDocuments();
  }, []);

  const fetchDocuments = async () => {
    try {
      const response = await fetch(
        "http://localhost:8080/api/v1/knowledge/documents"
      );
      if (response.ok) {
        const data = await response.json();
        setDocuments(data);
      }
    } catch (error) {
      console.error("Erro ao buscar documentos:", error);
      setMessage("Erro ao carregar a lista de documentos.");
    }
  };

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!file) return;

    setUploading(true);
    setMessage("");

    const formData = new FormData();
    formData.append("file", file);

    try {
      const response = await fetch(
        "http://localhost:8080/api/v1/knowledge/upload",
        {
          method: "POST",
          body: formData,
        }
      );

      if (response.ok) {
        setMessage("Documento enviado e processado com sucesso!");
        setFile(null);
        fetchDocuments();
      } else {
        const errorData = await response.json();
        setMessage(
          `Erro no upload: ${errorData.detail || response.statusText}`
        );
      }
    } catch (error) {
      setMessage("Erro de conexão com o servidor durante o upload.");
    } finally {
      setUploading(false);
    }
  };

  // --- Nova Função: Excluir Documento ---
  const handleDelete = async (filename) => {
    // Confirmação de segurança
    if (
      !window.confirm(
        `Tem certeza que deseja excluir o arquivo "${filename}"? Esta ação não pode ser desfeita.`
      )
    ) {
      return;
    }

    setMessage(`Excluindo ${filename}...`);

    try {
      const response = await fetch(
        `http://localhost:8080/api/v1/knowledge/documents/${filename}`,
        {
          method: "DELETE",
          headers: {
            // --- CABEÇALHO DE SEGURANÇA (MOCK) ---
            // Envia o papel "Adm" se o modo estiver ativo.
            // O backend usará isso para autorizar a exclusão.
            "X-User-Role": isAdmin ? "Adm" : "Solicitador",
          },
        }
      );

      if (response.ok) {
        setMessage(`Documento "${filename}" excluído com sucesso!`);
        // Atualiza a lista para remover o arquivo excluído
        fetchDocuments();
      } else {
        // Tenta ler a mensagem de erro do backend (ex: erro 403 Forbidden)
        let errorDetail = response.statusText;
        try {
          const errorData = await response.json();
          errorDetail = errorData.detail;
        } catch (e) {
          // Ignora se não for JSON
        }
        setMessage(`Erro ao excluir: ${errorDetail}`);
      }
    } catch (error) {
      console.error("Erro na exclusão:", error);
      setMessage("Erro de conexão com o servidor ao tentar excluir.");
    }
  };

  // --- Lógica de Sincronização (Mantida igual) ---
  const openSyncModal = async () => {
    setShowSyncModal(true);
    try {
      const res = await fetch("http://localhost:8080/api/v1/knowledge/manuals");
      if (res.ok) {
        const data = await res.json();
        setAvailableManuals(data);
      }
    } catch (err) {
      console.error("Erro ao listar manuais", err);
    }
  };

  const toggleManual = (manual) => {
    if (selectedManuals.includes(manual)) {
      setSelectedManuals(selectedManuals.filter((m) => m !== manual));
    } else {
      setSelectedManuals([...selectedManuals, manual]);
    }
  };

  const handleSync = async () => {
    setSyncing(true);
    try {
      const response = await fetch(
        "http://localhost:8080/api/v1/knowledge/ingest",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            manuals: selectedManuals,
            system_data: true,
          }),
        }
      );

      if (response.ok) {
        setMessage("Sincronização concluída com sucesso!");
        setShowSyncModal(false);
        fetchDocuments();
      } else {
        setMessage("Erro na sincronização.");
      }
    } catch (err) {
      setMessage("Erro de conexão durante sincronização.");
    } finally {
      setSyncing(false);
    }
  };

  return (
    <div className="p-6 bg-slate-950 min-h-screen text-slate-200">
      <header className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-slate-100">
            Base de Conhecimento
          </h1>
          <p className="text-slate-400">
            Gerencie os documentos que alimentam a IA.
          </p>
        </div>

        <div className="flex items-center space-x-4">
          {/* --- SWITCH DE MODO ADM (PARA TESTE) --- */}
          <label className="flex items-center cursor-pointer bg-slate-800 p-2 rounded border border-slate-700 hover:bg-slate-700 transition-colors">
            <input
              type="checkbox"
              checked={isAdmin}
              onChange={(e) => setIsAdmin(e.target.checked)}
              className="form-checkbox h-5 w-5 text-red-600 bg-slate-900 border-slate-600 rounded focus:ring-red-500"
            />
            <span className="ml-2 text-sm text-slate-300 font-medium">
              Modo ADM (Teste)
            </span>
          </label>

          <button
            onClick={openSyncModal}
            className="bg-cyan-600 hover:bg-cyan-700 text-white font-bold py-2 px-4 rounded shadow flex items-center transition-colors"
          >
            {/* Ícone de Sincronizar */}
            <svg
              className="w-5 h-5 mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              ></path>
            </svg>
            Sincronizar Base
          </button>
        </div>
      </header>

      {/* Modal de Sincronização (Mantido igual) */}
      {showSyncModal && (
        <div className="fixed inset-0 bg-slate-900/80 backdrop-blur-sm overflow-y-auto h-full w-full flex items-center justify-center z-50">
          <div className="bg-slate-800 p-8 rounded-lg shadow-xl w-full max-w-2xl border border-slate-700">
            <h2 className="text-2xl font-bold mb-4 text-slate-100">
              Sincronizar Base de Conhecimento
            </h2>
            <p className="mb-4 text-slate-400">
              Selecione os manuais para ingestão. Dados do sistema (RCMs,
              Solicitações) serão incluídos automaticamente.
            </p>

            <div className="mb-4 border border-slate-600 rounded p-4 max-h-60 overflow-y-auto bg-slate-900">
              {availableManuals.length === 0 ? (
                <p className="text-slate-500">
                  Nenhum manual encontrado na pasta data/manuais.
                </p>
              ) : (
                availableManuals.map((manual, idx) => (
                  <div key={idx} className="flex items-center mb-2">
                    <input
                      type="checkbox"
                      id={`manual-${idx}`}
                      checked={selectedManuals.includes(manual)}
                      onChange={() => toggleManual(manual)}
                      className="mr-2 h-4 w-4 text-cyan-600 bg-slate-700 border-slate-500 rounded focus:ring-cyan-500"
                    />
                    <label
                      htmlFor={`manual-${idx}`}
                      className="text-sm text-slate-300 truncate cursor-pointer"
                    >
                      {manual}
                    </label>
                  </div>
                ))
              )}
            </div>

            <div className="flex justify-end space-x-4">
              <button
                onClick={() => setShowSyncModal(false)}
                className="px-4 py-2 bg-slate-700 text-slate-300 rounded hover:bg-slate-600 transition-colors"
                disabled={syncing}
              >
                Cancelar
              </button>
              <button
                onClick={handleSync}
                className="px-4 py-2 bg-cyan-600 text-white rounded hover:bg-cyan-700 flex items-center transition-colors"
                disabled={syncing}
              >
                {syncing ? (
                  <>
                    <svg
                      className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                      ></circle>
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      ></path>
                    </svg>
                    Sincronizando...
                  </>
                ) : (
                  "Iniciar Sincronização"
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Área de Upload (Mantida igual) */}
      <div className="bg-slate-900 p-6 rounded-lg shadow-lg border border-slate-800 mb-8">
        <h2 className="text-xl font-semibold mb-4 text-cyan-400">
          Upload Manual
        </h2>
        <form onSubmit={handleUpload} className="flex items-center space-x-4">
          <input
            type="file"
            accept=".pdf,.docx"
            onChange={handleFileChange}
            className="block w-full text-sm text-slate-400
              file:mr-4 file:py-2 file:px-4
              file:rounded-full file:border-0
              file:text-sm file:font-semibold
              file:bg-slate-800 file:text-cyan-400
              hover:file:bg-slate-700 cursor-pointer"
          />
          <button
            type="submit"
            disabled={uploading || !file}
            className={`py-2 px-4 rounded font-bold text-white transition-colors ${
              uploading || !file
                ? "bg-slate-700 cursor-not-allowed text-slate-500"
                : "bg-cyan-600 hover:bg-cyan-700"
            }`}
          >
            {uploading ? "Enviando..." : "Enviar"}
          </button>
        </form>
        {message && (
          <div
            className={`mt-4 p-3 rounded border ${
              message.includes("Erro") || message.includes("Acesso negado")
                ? "bg-red-900/30 text-red-400 border-red-900"
                : "bg-green-900/30 text-green-400 border-green-900"
            }`}
          >
            {message}
          </div>
        )}
      </div>

      {/* Lista de Documentos (Atualizada com botão de exclusão) */}
      <div className="bg-slate-900 p-6 rounded-lg shadow-lg border border-slate-800">
        <h2 className="text-xl font-semibold mb-4 text-cyan-400">
          Documentos Indexados
        </h2>
        {documents.length === 0 ? (
          <p className="text-slate-500">Nenhum documento encontrado.</p>
        ) : (
          <ul className="divide-y divide-slate-800">
            {documents.map((doc, index) => (
              <li
                key={index}
                // Adicionado group para facilitar hover no botão
                className="py-3 flex justify-between items-center hover:bg-slate-800/50 px-2 rounded transition-colors group"
              >
                <div className="flex items-center">
                  {/* Ícone de documento */}
                  <svg
                    className="w-5 h-5 text-slate-500 mr-3"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    ></path>
                  </svg>
                  <span className="text-slate-300 font-medium">
                    {doc.filename}
                  </span>
                </div>

                <div className="flex items-center space-x-4">
                  <span className="text-sm text-slate-500 bg-slate-800 px-2 py-1 rounded-full">
                    {doc.chunks} chunks
                  </span>

                  {/* --- BOTÃO DE EXCLUIR (CONDICIONAL) --- */}
                  {/* Só aparece se isAdmin for true */}
                  {isAdmin && (
                    <button
                      onClick={() => handleDelete(doc.filename)}
                      className="text-slate-500 hover:text-red-500 transition-colors p-1 rounded hover:bg-red-900/20 focus:outline-none focus:ring-2 focus:ring-red-500 opacity-0 group-hover:opacity-100"
                      title={`Excluir ${doc.filename}`}
                    >
                      <svg
                        className="w-5 h-5"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="2"
                          d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                        ></path>
                      </svg>
                    </button>
                  )}
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
};

export default Knowledge;
