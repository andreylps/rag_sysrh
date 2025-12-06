import React, { useState, useEffect } from "react";
import {
  Target,
  TrendingUp,
  DollarSign,
  AlertTriangle,
  Clock,
  CheckCircle,
  Search,
  ArrowRight,
} from "lucide-react";
import { API_BASE_URL } from "../config";

const CommercialSniper = () => {
  const [loadingScan, setLoadingScan] = useState(false);
  const [loadingList, setLoadingList] = useState(true);
  const [opportunities, setOpportunities] = useState([]);
  const [stats, setStats] = useState({
    total: 0,
    potentialRevenue: 0,
    avgRoi: 0,
  });

  const fetchOpportunities = async () => {
    setLoadingList(true);
    try {
      const response = await fetch(`${API_BASE_URL}/commercial/opportunities`);
      if (response.ok) {
        const data = await response.json();
        setOpportunities(data);
        calculateStats(data);
      }
    } catch (error) {
      console.error("Erro ao buscar oportunidades:", error);
    } finally {
      setLoadingList(false);
    }
  };

  const calculateStats = (data) => {
    const total = data.length;
    const potentialRevenue = data.reduce(
      (acc, curr) => acc + (curr.estimativa_pf || 0) * 150, // Ex: R$ 150/PF
      0
    );
    // Mock ROI calculation
    const avgRoi = total > 0 ? 350 : 0; // 350% ROI fictício médio

    setStats({ total, potentialRevenue, avgRoi });
  };

  useEffect(() => {
    fetchOpportunities();
  }, []);

  const handleScan = async () => {
    setLoadingScan(true);
    try {
      const response = await fetch(`${API_BASE_URL}/commercial/scan`, {
        method: "POST",
      });
      if (response.ok) {
        // Inicia polling para verificar resultados
        let attempts = 0;
        const maxAttempts = 30; // 30 tentativas * 2s = 60 segundos de timeout

        const pollInterval = setInterval(async () => {
          attempts++;
          const hasResults = await fetchOpportunities();

          if (hasResults || attempts >= maxAttempts) {
            clearInterval(pollInterval);
            setLoadingScan(false);
          }
        }, 2000);
      } else {
        setLoadingScan(false);
      }
    } catch (error) {
      console.error("Erro ao disparar scan:", error);
      setLoadingScan(false);
    }
  };

  const getSeverityColor = (severity) => {
    switch (severity?.toLowerCase()) {
      case "alta":
        return "bg-red-500/20 text-red-400 border-red-500/30";
      case "média":
        return "bg-yellow-500/20 text-yellow-400 border-yellow-500/30";
      case "baixa":
        return "bg-blue-500/20 text-blue-400 border-blue-500/30";
      default:
        return "bg-gray-500/20 text-gray-400 border-gray-500/30";
    }
  };

  return (
    <div className="space-y-8">
      {/* Hero Section */}
      <div className="bg-gradient-to-r from-gray-800 to-gray-900 rounded-2xl p-8 border border-gray-700 shadow-xl relative overflow-hidden">
        <div className="absolute top-0 right-0 p-4 opacity-10">
          <Target size={200} />
        </div>
        <div className="relative z-10">
          <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
            <Target className="text-red-500" /> Agente Sniper
          </h2>
          <p className="text-gray-300 max-w-2xl mb-8 text-lg">
            Nossa IA analisa o código fonte do cliente em busca de dívidas
            técnicas, riscos de segurança e oportunidades de modernização que
            podem ser convertidas em novos contratos.
          </p>
          <button
            onClick={handleScan}
            disabled={loadingScan}
            className={`
              flex items-center gap-3 px-8 py-4 rounded-xl font-bold text-lg transition-all transform hover:scale-105
              ${
                loadingScan
                  ? "bg-gray-600 cursor-not-allowed"
                  : "bg-gradient-to-r from-red-600 to-red-500 hover:from-red-500 hover:to-red-400 text-white shadow-lg shadow-red-500/30"
              }
            `}
          >
            {loadingScan ? (
              <>
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white"></div>
                Analisando Código...
              </>
            ) : (
              <>
                <Search size={24} />
                Disparar Varredura de Código
              </>
            )}
          </button>
        </div>
      </div>

      {/* KPI Dashboard */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-gray-800 rounded-xl p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-400 font-medium">Oportunidades</h3>
            <div className="p-2 bg-blue-500/20 rounded-lg text-blue-400">
              <TrendingUp size={20} />
            </div>
          </div>
          <p className="text-3xl font-bold text-white">{stats.total}</p>
          <p className="text-sm text-gray-500 mt-1">Identificadas pela IA</p>
        </div>

        <div className="bg-gray-800 rounded-xl p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-400 font-medium">Potencial (Estimado)</h3>
            <div className="p-2 bg-green-500/20 rounded-lg text-green-400">
              <DollarSign size={20} />
            </div>
          </div>
          <p className="text-3xl font-bold text-white">
            {stats.potentialRevenue.toLocaleString("pt-BR", {
              style: "currency",
              currency: "BRL",
            })}
          </p>
          <p className="text-sm text-gray-500 mt-1">Baseado em PF</p>
        </div>

        <div className="bg-gray-800 rounded-xl p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-400 font-medium">ROI Médio</h3>
            <div className="p-2 bg-purple-500/20 rounded-lg text-purple-400">
              <CheckCircle size={20} />
            </div>
          </div>
          <p className="text-3xl font-bold text-white">{stats.avgRoi}%</p>
          <p className="text-sm text-gray-500 mt-1">
            Retorno sobre Investimento
          </p>
        </div>
      </div>

      {/* Opportunities List */}
      <div>
        <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
          <TrendingUp className="text-blue-400" /> Oportunidades de Negócio
        </h3>

        {loadingList ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
            <p className="text-gray-400">Carregando oportunidades...</p>
          </div>
        ) : opportunities.length === 0 ? (
          <div className="text-center py-12 bg-gray-800 rounded-xl border border-gray-700 border-dashed">
            <Search className="h-12 w-12 text-gray-600 mx-auto mb-4" />
            <p className="text-gray-400 text-lg">
              Nenhuma oportunidade encontrada ainda.
            </p>
            <p className="text-gray-500">
              Clique em "Disparar Varredura" para iniciar a análise.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-6">
            {opportunities.map((opp, index) => (
              <div
                key={index}
                className="bg-gray-800 rounded-xl p-6 border border-gray-700 hover:border-blue-500/50 transition-colors group"
              >
                <div className="flex flex-col md:flex-row gap-6">
                  <div className="flex-1">
                    <div className="flex items-start justify-between mb-2">
                      <h4 className="text-xl font-bold text-white group-hover:text-blue-400 transition-colors">
                        {opp.titulo}
                      </h4>
                      <div className="flex gap-2">
                        <span
                          className={`px-3 py-1 rounded-full text-xs font-bold border ${getSeverityColor(
                            opp.severidade
                          )}`}
                        >
                          {opp.severidade?.toUpperCase()}
                        </span>
                        <span className="px-3 py-1 rounded-full text-xs font-bold bg-gray-700 text-gray-300 border border-gray-600">
                          {opp.estimativa_pf} PF
                        </span>
                      </div>
                    </div>

                    <p className="text-gray-400 mb-4 text-sm font-mono bg-gray-900/50 p-2 rounded">
                      Arquivo: {opp.arquivo}
                    </p>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                      <div>
                        <h5 className="text-sm font-bold text-gray-500 uppercase mb-2 flex items-center gap-1">
                          <AlertTriangle size={14} /> Problema Técnico
                        </h5>
                        <p className="text-gray-300 text-sm leading-relaxed">
                          {opp.descricao_tecnica}
                        </p>
                      </div>
                      <div>
                        <h5 className="text-sm font-bold text-green-500 uppercase mb-2 flex items-center gap-1">
                          <DollarSign size={14} /> Argumento de Venda
                        </h5>
                        <p className="text-gray-300 text-sm leading-relaxed italic border-l-2 border-green-500/30 pl-3">
                          "{opp.argumento_comercial}"
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center justify-end">
                      <button
                        onClick={() =>
                          alert(
                            `Funcionalidade de Geração de Proposta para "${opp.titulo}" será implementada na próxima fase!`
                          )
                        }
                        className="flex items-center gap-2 text-sm font-medium text-blue-400 hover:text-blue-300 transition-colors"
                      >
                        Gerar Proposta Comercial <ArrowRight size={16} />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default CommercialSniper;
