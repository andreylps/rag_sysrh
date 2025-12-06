import React from "react";

const PipelineCard = ({ title, count, icon: Icon, colorTheme = "blue" }) => {
  // Mapas de cores baseados no tema
  const colorMap = {
    blue: {
      bg: "bg-blue-900/20",
      border: "border-blue-800",
      text: "text-blue-400",
      iconBg: "bg-blue-900/50",
    },
    yellow: {
      bg: "bg-yellow-900/20",
      border: "border-yellow-800",
      text: "text-yellow-400",
      iconBg: "bg-yellow-900/50",
    },
    purple: {
      bg: "bg-purple-900/20",
      border: "border-purple-800",
      text: "text-purple-400",
      iconBg: "bg-purple-900/50",
    },
    orange: {
      bg: "bg-orange-900/20",
      border: "border-orange-800",
      text: "text-orange-400",
      iconBg: "bg-orange-900/50",
    },
    cyan: {
      bg: "bg-cyan-900/20",
      border: "border-cyan-800",
      text: "text-cyan-400",
      iconBg: "bg-cyan-900/50",
    },
  };

  const theme = colorMap[colorTheme] || colorMap.blue;

  return (
    <div
      className={`${theme.bg} border ${theme.border} rounded-xl p-4 flex items-center justify-between shadow-lg transition-transform hover:scale-105`}
    >
      <div>
        <p className="text-slate-400 text-sm font-medium mb-1">{title}</p>
        <div className="flex items-baseline gap-1">
          {count === null || count === undefined ? (
            <div className="h-8 w-8 animate-pulse bg-slate-700 rounded"></div>
          ) : (
            <span className={`text-3xl font-bold ${theme.text}`}>{count}</span>
          )}
          <span className="text-xs text-slate-500">issues</span>
        </div>
      </div>
      <div className={`p-3 rounded-lg ${theme.iconBg}`}>
        {Icon && <Icon className={`w-6 h-6 ${theme.text}`} />}
      </div>
    </div>
  );
};

export default PipelineCard;
