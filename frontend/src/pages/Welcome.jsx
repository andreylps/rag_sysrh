import React from "react";
import { Bot } from "lucide-react";

const Welcome = () => {
  return (
    <div className="flex flex-col items-center justify-center h-full text-center p-8 animate-fade-in relative overflow-hidden">
      <style>{`
        @keyframes soft-spotlight {
          0% { transform: translateX(-150%) skewX(-25deg); opacity: 0; }
          20% { opacity: 0.3; }
          50% { opacity: 0.5; }
          80% { opacity: 0.3; }
          100% { transform: translateX(150%) skewX(-25deg); opacity: 0; }
        }
        .spotlight-effect {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: linear-gradient(
            90deg, 
            transparent 0%, 
            rgba(59, 130, 246, 0.1) 20%, 
            rgba(147, 197, 253, 0.2) 50%, 
            rgba(59, 130, 246, 0.1) 80%, 
            transparent 100%
          );
          animation: soft-spotlight 2.5s ease-in-out 1 forwards;
          pointer-events: none;
        }
      `}</style>

      <div className="relative bg-blue-500/10 p-8 rounded-full mb-8 shadow-lg shadow-blue-500/20 border border-blue-500/20 overflow-hidden group">
        <Bot size={80} className="text-blue-400 relative z-10" />
        {/* Camada de Animação de Luz */}
        <div className="spotlight-effect"></div>
      </div>

      <h1 className="text-4xl md:text-5xl font-bold text-white mb-4 tracking-tight">
        PORTAL DE INTELIGÊNCIA ARTIFICIAL
      </h1>

      <div className="h-1 w-32 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full mb-8"></div>

      <h2 className="text-2xl md:text-3xl text-gray-300 font-light tracking-widest uppercase">
        SEJA BEM-VINDO
      </h2>

      <p className="mt-8 text-gray-500 max-w-lg">
        Selecione uma opção no menu lateral para iniciar suas operações.
      </p>
    </div>
  );
};

export default Welcome;
