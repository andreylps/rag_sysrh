import React from "react";
import {
  ExternalLink,
  ShieldAlert,
  Activity,
  BarChart3,
  Bug,
} from "lucide-react";

const LangSmith = () => {
  const projectUrl = "https://smith.langchain.com/";

  return (
    <div className="p-6 max-w-7xl mx-auto h-full flex flex-col">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-white flex items-center gap-3">
            <ShieldAlert className="text-orange-500" />
            Observabilidade (LangSmith)
          </h1>
          <p className="text-gray-400 mt-1">
            Plataforma de engenharia para LLMs: Debug, Testes e Monitoramento.
          </p>
        </div>
      </div>

      {/* Main Launchpad Card */}
      <div className="flex-1 flex flex-col items-center justify-center bg-gray-900/50 rounded-xl border border-gray-700 p-12 text-center">
        <div className="bg-orange-500/10 p-6 rounded-full mb-6">
          <Activity size={64} className="text-orange-500" />
        </div>

        <h2 className="text-2xl font-bold text-white mb-4">
          Visualização Externa Necessária
        </h2>

        <p className="text-gray-400 max-w-2xl mb-8 text-lg">
          Por motivos de segurança (CSP), o painel do LangSmith não pode ser
          embutido diretamente nesta aplicação. Utilize o botão abaixo para
          acessar o dashboard completo em uma nova aba.
        </p>

        <a
          href={projectUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-3 px-8 py-4 bg-orange-600 hover:bg-orange-700 text-white rounded-xl transition-all transform hover:scale-105 font-semibold text-lg shadow-lg shadow-orange-900/20"
        >
          <ExternalLink size={24} />
          Acessar LangSmith Dashboard
        </a>

        <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-8 w-full max-w-4xl">
          <div className="p-6 bg-gray-800/30 rounded-xl border border-gray-700/50 hover:border-orange-500/30 transition-colors">
            <Bug className="w-8 h-8 text-orange-400 mb-4 mx-auto" />
            <h3 className="text-white font-semibold mb-2">Debug de Traces</h3>
            <p className="text-sm text-gray-400">
              Inspecione cada passo da execução dos agentes, inputs e outputs.
            </p>
          </div>

          <div className="p-6 bg-gray-800/30 rounded-xl border border-gray-700/50 hover:border-blue-500/30 transition-colors">
            <BarChart3 className="w-8 h-8 text-blue-400 mb-4 mx-auto" />
            <h3 className="text-white font-semibold mb-2">Métricas</h3>
            <p className="text-sm text-gray-400">
              Analise latência, custo de tokens e taxas de erro por modelo.
            </p>
          </div>

          <div className="p-6 bg-gray-800/30 rounded-xl border border-gray-700/50 hover:border-green-500/30 transition-colors">
            <ShieldAlert className="w-8 h-8 text-green-400 mb-4 mx-auto" />
            <h3 className="text-white font-semibold mb-2">Avaliação</h3>
            <p className="text-sm text-gray-400">
              Crie datasets e execute testes de regressão nos seus prompts.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LangSmith;
