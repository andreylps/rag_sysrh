import sys
import os
import asyncio

# Add project root to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from src.rag_sysrh.data_ingestion import DataIngestion

def main():
    print("🚀 Starting Manual Data Ingestion...")
    
    try:
        ingestion = DataIngestion(
            data_directory="data",
            structured_data_path="data/solicitacoes.csv",
            rcm_data_path="data/rcms_01.csv",
            single_manual_path=None # Process all manuals
        )
        
        # Run ingestion (clearing DB first to ensure fresh state)
        ingestion.run_ingestion(clear_db=True)
        
        print("✅ Ingestion Completed Successfully!")
        
    except Exception as e:
        print(f"❌ Ingestion Failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
