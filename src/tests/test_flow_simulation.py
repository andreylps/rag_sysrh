import unittest
from unittest.mock import AsyncMock, MagicMock, patch
import sys
import os

# Add src to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

from src.api.v1.endpoints.solicitacoes import processar_solicitacao_background
from src.rag_sysrh.analista_workflow import RelatorioAnalise, DetalhesEvolutiva
from src.agents.dev_agent import run_dev_agent
from src.rag_sysrh.tools.solicitation_tools import CreateSolicitationTool

class TestFlowSimulation(unittest.IsolatedAsyncioTestCase):

    async def test_scenario_1_evolutiva_flow(self):
        """
        Scenario 1: Evolutiva Flow (RCM Required)
        - Input: Request type "Evolutiva"
        - Expected: RCM generated, Label 'status:aguardando-validacao-rcm'
        """
        print("\n--- Testing Scenario 1: Evolutiva Flow ---")
        
        # Mock dependencies
        with patch('src.api.v1.endpoints.solicitacoes.AnalistaWorkflow') as MockWorkflow, \
             patch('src.services.github_service.update_issue_labels', new_callable=AsyncMock) as mock_update_labels, \
             patch('src.api.v1.endpoints.solicitacoes.post_comment', new_callable=AsyncMock) as mock_post_comment, \
             patch('src.api.v1.endpoints.solicitacoes.get_tools') as mock_get_tools:

            # Setup Mock Workflow
            mock_agent_instance = MockWorkflow.return_value
            
            # Mock Analysis Result
            mock_result = RelatorioAnalise(
                solicitacao_id=123,
                tipo_problema="Solicitação de Melhoria",
                tipo_solicitacao="Evolutiva",
                resumo_problema="Test Evolutiva",
                diagnostico="Diagnosis",
                complexidade="Média",
                solucao_sugerida="Solution",
                nivel_esforco="Médio",
                esforco_resolucao_dias="3-7 dias",
                detalhes_evolutiva=DetalhesEvolutiva(
                    data_prevista_entrega="01/01/2025",
                    estimativa_pontos_funcao=10,
                    prazo_dias_uteis=5
                )
            )
            mock_agent_instance.arun = AsyncMock(return_value=mock_result)

            # Execute
            await processar_solicitacao_background(
                issue_id=123,
                descricao="Preciso de uma nova tela.",
                tipo_solicitacao="Evolutiva",
                prioridade_sugerida="Média"
            )

            # Verify
            # 1. Check if agent was called with correct ID
            mock_agent_instance.arun.assert_called_once()
            call_args = mock_agent_instance.arun.call_args
            self.assertEqual(call_args.kwargs['solicitacao_id'], 123)
            
            # 2. Check if default label was NOT added (because it's Evolutiva)
            # The code logic: if evolutiva, should_add_default_label = False
            # So update_issue_labels should NOT be called with 'status:aguardando-validacao'
            # However, AnalistaWorkflow ITSELF calls update_issue_labels with 'status:aguardando-validacao-rcm'
            # But here we are mocking AnalistaWorkflow, so we only test what processar_solicitacao_background does.
            # processar_solicitacao_background should NOT call update_issue_labels for Evolutiva.
            
            mock_update_labels.assert_not_called()
            print("✅ Evolutiva Flow: Correctly skipped default label (RCM handled by workflow).")

    async def test_scenario_2_fast_track_flow(self):
        """
        Scenario 2: Fast Track Flow (No RCM)
        - Input: Request type "Corretiva"
        - Expected: No RCM, Label 'status:aguardando-liberacao-dev'
        """
        print("\n--- Testing Scenario 2: Fast Track Flow ---")
        
        with patch('src.api.v1.endpoints.solicitacoes.AnalistaWorkflow') as MockWorkflow, \
             patch('src.services.github_service.update_issue_labels', new_callable=AsyncMock) as mock_update_labels, \
             patch('src.api.v1.endpoints.solicitacoes.post_comment', new_callable=AsyncMock) as mock_post_comment, \
             patch('src.api.v1.endpoints.solicitacoes.get_tools') as mock_get_tools:

            mock_agent_instance = MockWorkflow.return_value
            
            mock_result = RelatorioAnalise(
                solicitacao_id=124,
                tipo_problema="Relato de Erro",
                tipo_solicitacao="Corretiva",
                resumo_problema="Bug fix",
                diagnostico="Error found",
                complexidade="Baixa",
                solucao_sugerida="Fix it",
                nivel_esforco="Baixo",
                esforco_resolucao_dias="1 dia",
                detalhes_evolutiva=None
            )
            mock_agent_instance.arun = AsyncMock(return_value=mock_result)

            await processar_solicitacao_background(
                issue_id=124,
                descricao="Erro no sistema.",
                tipo_solicitacao="Corretiva",
                prioridade_sugerida="Alta"
            )

            # Verify
            # Should add 'status:aguardando-liberacao-dev'
            mock_update_labels.assert_called_once()
            call_args = mock_update_labels.call_args
            self.assertEqual(call_args.kwargs['issue_number'], 124)
            self.assertIn("status:aguardando-liberacao-dev", call_args.kwargs['add_labels'])
            print("✅ Fast Track Flow: Correctly added 'status:aguardando-liberacao-dev'.")

    async def test_scenario_3_chat_tool(self):
        """
        Scenario 3: Chat Request Creation Tool
        - Input: Tool call parameters
        - Expected: create_issue called
        """
        print("\n--- Testing Scenario 3: Chat Tool ---")
        
        tool = CreateSolicitationTool()
        
        with patch('src.rag_sysrh.tools.solicitation_tools.create_issue', new_callable=AsyncMock) as mock_create_issue:
            mock_create_issue.return_value = 999
            
            result = await tool._arun(
                title="System Crash",
                description="It crashed.",
                priority="Alta",
                solicitation_type="Corretiva"
            )
            
            mock_create_issue.assert_called_once()
            self.assertIn("999", result)
            print("✅ Chat Tool: Correctly called create_issue.")

    async def test_scenario_4_dev_agent_generation(self):
        """
        Scenario 4: Dev Agent Phase 1 (Generation)
        - Input: Issue assigned to Dev Agent
        - Expected: Code implemented (mock), Label updated to 'status:aguardando-review-tecnico'
        """
        print("\n--- Testing Scenario 4: Dev Agent Phase 1 (Generation) ---")
        
        issue_data = {"title": "Implement Feature X", "body": "Do it."}
        
        with patch('src.agents.dev_agent.agent_executor.ainvoke', new_callable=AsyncMock) as mock_agent_invoke, \
             patch('src.agents.dev_agent.github_post_comment', new_callable=AsyncMock) as mock_post_comment, \
             patch('src.agents.dev_agent.github_apply_labels', new_callable=AsyncMock) as mock_apply_labels:

            # Mock Agent Response
            mock_agent_invoke.return_value = {
                "messages": [MagicMock(content="Code implemented successfully.")]
            }
            
            # Execute Phase 1
            result = await run_dev_agent(issue_number=125, issue_data=issue_data)

            # Verify
            self.assertEqual(result, "Code implemented successfully.")
            
            # Check Label Updates
            # Should add 'status:aguardando-review-tecnico'
            mock_apply_labels.assert_called()
            call_args = mock_apply_labels.call_args
            self.assertEqual(call_args.kwargs['issue_number'], 125)
            self.assertIn("status:aguardando-review-tecnico", call_args.kwargs['labels_to_add'])
            
            print("✅ Dev Agent Phase 1: Code generated and moved to Technical Review.")

    async def test_scenario_5_dev_agent_execution(self):
        """
        Scenario 5: Dev Agent Phase 2 (Execution/Doc/QA)
        - Input: Technical Review Approved
        - Expected: Manual generated (mock), QA passed (mock), Label updated to 'status:aceite-homologacao'
        """
        print("\n--- Testing Scenario 5: Dev Agent Phase 2 (Execution) ---")
        
        issue_data = {"title": "Implement Feature X", "body": "Do it."}
        
        from src.agents.dev_agent import run_dev_agent_execution
        
        with patch('src.agents.dev_agent.generate_or_update_operational_manual') as mock_gen_manual, \
             patch('src.agents.dev_agent.validate_operational_manual', new_callable=AsyncMock) as mock_validate_manual, \
             patch('src.agents.dev_agent.github_post_comment', new_callable=AsyncMock) as mock_post_comment, \
             patch('src.agents.dev_agent.github_apply_labels', new_callable=AsyncMock) as mock_apply_labels:

            # Mock Manual Generation
            mock_gen_manual.return_value = "/path/to/manual.md"
            
            # Mock QA Validation (Success)
            mock_qa_result = MagicMock()
            mock_qa_result.is_compliant = True
            mock_validate_manual.return_value = mock_qa_result

            # Execute Phase 2
            result = await run_dev_agent_execution(issue_number=125, issue_data=issue_data)

            # Verify
            self.assertEqual(result, "Fase 2 concluída com sucesso.")
            
            # Check QA Validation
            mock_validate_manual.assert_called_once()
            
            # Check Label Updates (Success path)
            # Should add 'status:aceite-homologacao'
            mock_apply_labels.assert_called()
            call_args = mock_apply_labels.call_args
            self.assertEqual(call_args.kwargs['issue_number'], 125)
            self.assertIn("status:aceite-homologacao", call_args.kwargs['labels_to_add'])
            
            # Check Success Comment
            mock_post_comment.assert_called()
            success_call = [call for call in mock_post_comment.call_args_list if "Documentação Aprovada" in call.args[1]]
            self.assertTrue(success_call, "Success comment not posted")
            
            print("✅ Dev Agent Phase 2: QA passed and moved to Homologation.")

if __name__ == '__main__':
    unittest.main()
