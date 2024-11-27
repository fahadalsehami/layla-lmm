# backend/services/rag_service.py

from typing import Dict, Any, List
import anthropic
import openai
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import FAISS
from langchain.text_splitter import RecursiveCharacterTextSplitter
from backend.core.config import settings
from backend.core.logging import logger

class RAGSystem:
    """Retrieval Augmented Behavioral Generative System"""
    
    def __init__(self):
        self.anthropic_client = anthropic.Anthropic(
            api_key=settings.ANTHROPIC_API_KEY
        )
        self.openai_client = openai.OpenAI(
            api_key=settings.OPENAI_API_KEY
        )
        
        # Initialize embeddings
        self.embeddings = OpenAIEmbeddings()
        
        # Load RDoC knowledge base
        self.rdoc_kb = self._load_rdoc_knowledge_base()
    
    def _load_rdoc_knowledge_base(self) -> FAISS:
        """Load and index RDoC framework knowledge"""
        # Load RDoC documents
        rdoc_docs = self._load_rdoc_documents()
        
        # Split documents
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
        texts = text_splitter.split_documents(rdoc_docs)
        
        # Create vector store
        vector_store = FAISS.from_documents(texts, self.embeddings)
        return vector_store
    
    async def analyze_assessment(
        self,
        assessment_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Analyze assessment using RAG system"""
        
        # Retrieve relevant RDoC context
        context = self._retrieve_rdoc_context(assessment_data)
        
        # Generate analysis using Claude
        claude_analysis = await self._generate_claude_analysis(
            assessment_data,
            context
        )
        
        # Generate recommendations using GPT-4
        gpt4_recommendations = await self._generate_gpt4_recommendations(
            assessment_data,
            context,
            claude_analysis
        )
        
        return {
            "rdoc_context": context,
            "claude_analysis": claude_analysis,
            "gpt4_recommendations": gpt4_recommendations
        }
    
    async def _generate_claude_analysis(
        self,
        assessment_data: Dict[str, Any],
        context: str
    ) -> Dict[str, Any]:
        """Generate analysis using Claude"""
        
        prompt = f"""
        Based on the provided assessment data and RDoC framework context, 
        provide a comprehensive analysis of the patient's mental health status.
        
        Assessment Data:
        {assessment_data}
        
        RDoC Context:
        {context}
        
        Please analyze:
        1. Key symptoms and their severity
        2. Relevant RDoC domains and constructs
        3. Potential underlying mechanisms
        4. Risk assessment
        5. Treatment implications
        """
        
        response = await self.anthropic_client.messages.create(
            model="claude-3-sonnet-20240229",
            max_tokens=2000,
            temperature=0.7,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )
        
        return response.content