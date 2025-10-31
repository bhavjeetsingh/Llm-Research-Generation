import os
import sys
from datetime import datetime
from typing import Optional
from langgraph.types import Send

current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, "../../"))
sys.path.append(project_root)

from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, get_buffer_string
from langchain_community.tools.tavily_search import TavilySearchResults

from docx import document
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

from research_and_analyst.backend_server.models import(
    Analyst,
    Perspectives,
    GenerateAnalystsState,
    InterviewState,
    ResearchGraphState,
)
from research_and_analyst.utils.model_loader import ModelLoader

def buil_interview_graph(llm,tavily_search=None):
    """
    Args:
        llm (_type_): _description_
        tavily_search (_type_, optional): _description_. Defaults to None.
    """
    def generation_question(state:InterviewState):
        pass
    def search_web(state:InterviewState):
        pass
    def generate_answer(state:InterviewState):
        pass
    def save_interview(state:InterviewState):
        pass
    def write_section(state:InterviewState):
        pass
class AutonomousReportGenerator:
    def __init__(self):
        """_summary_
        """
        pass

    def create_analyst(self):
        """_summary_
        """
        pass
    
    def human_feedback(self):
        """_summary_
        """
        pass

    def write_report(self):
        """_summary_
        """
        pass

    def write_introduction(self):
        """_summary_
        """
        pass

    def write_conclusion(self):
        """_summary_
        """
        pass

    def finalize_report(self):
        """_summary_
        """
        pass

    def save_report(self):
        """_summary_
        """
        pass
    
    def _save_as_docx(self):
        """ _summary_
        """
        pass

    def build_graph(self):
        """_summary_
        """
        pass

if __name__ == "__main__":
        """_summary_
        """
        llm = ModelLoader().load_llm()
        print(llm.invoke('hello').content)
        reporter = AutonomousReportGenerator()
        reporter.build_graph()
