rail_spec_topical = """
<rail version="0.1">
<output>
    <bool name="is_on_topic"
          description="Indica se a pergunta do usuário está relacionada aos tópicos de SYSRH, RCM, evolutivas ou faturamento."
          on-fail-is-on-topic="fix"
    />
</output>
<prompt>
A pergunta do usuário é:
${user_input}

A pergunta está relacionada a algum dos seguintes tópicos?
- Sistema SYSRH
- Requisições de Mudança (RCM)
- Análise de evolutivas de software
- Planejamento de projetos de software
- Faturamento de projetos
- Manuais técnicos do sistema

Responda APENAS com o JSON.
</prompt>
</rail>
"""

rail_spec_cypher = """
<rail version="0.1">
<output>
    <string name="cypher"
            description="A consulta Cypher gerada."
            format="bug-free-cypher"
            on-fail-cypher="reask"
    />
</output>
<prompt>
Gere uma consulta Cypher válida para responder à pergunta do usuário.
A consulta deve ser APENAS de leitura (MATCH, RETURN, WITH, WHERE, ORDER BY, LIMIT).
NÃO use operações de escrita (CREATE, DELETE, SET, MERGE, DETACH, REMOVE).

Schema:
${schema}

Pergunta:
${question}

Responda APENAS com o JSON.
</prompt>
</rail>
"""
