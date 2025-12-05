import React, { useState } from "react";
import { LayoutDashboard, FileText, Bot } from "lucide-react";
import POCGenerator from "./POCGenerator";
import CommercialDashboard from "../components/CommercialDashboard";
import CommercialSniper from "../components/CommercialSniper";

const CommercialRoom = () => {
  const [activeTab, setActiveTab] = useState("sniper");

  const tabs = [
    {
      id: "sniper",
      label: "Agente Sniper",
      icon: Bot,
      component: CommercialSniper,
    },
    {
      id: "indicators",
      label: "Indicadores Comercial",
      icon: LayoutDashboard,
      component: CommercialDashboard,
    },
    {
      id: "poc",
      label: "Gerador de POC",
      icon: FileText,
      component: POCGenerator,
    },
  ];

  return (
    <div className="p-6 min-h-screen bg-gray-900 text-gray-100">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Sala Comercial</h1>
        <p className="text-gray-400">
          Gestão estratégica, indicadores e geração de propostas.
        </p>
      </header>

      {/* Tabs Navigation */}
      <div className="flex border-b border-gray-700 mb-8">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-6 py-3 font-medium transition-colors relative ${
                activeTab === tab.id
                  ? "text-blue-400"
                  : "text-gray-400 hover:text-gray-200"
              }`}
            >
              <Icon size={18} />
              {tab.label}
              {activeTab === tab.id && (
                <div className="absolute bottom-0 left-0 w-full h-0.5 bg-blue-400" />
              )}
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      <div className="animate-fade-in">
        {tabs.map((tab) => {
          if (activeTab !== tab.id) return null;
          const Component = tab.component;
          return <Component key={tab.id} />;
        })}
      </div>
    </div>
  );
};

export default CommercialRoom;
