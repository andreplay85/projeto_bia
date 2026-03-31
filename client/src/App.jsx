import React, { useState, useEffect } from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { ThemeProvider } from "./contexts/ThemeContext.jsx";
import { LogProvider, useLog } from "./contexts/LogContext.jsx";
import Header from "./components/Header.jsx";
import Footer from "./components/Footer.jsx";
import Tasks from "./components/Tasks.jsx";
import AddTask from "./components/AddTask.jsx";
import About from "./components/About.jsx";
import DebugLogs from "./components/DebugLogs.jsx";

function AppContent() {
  const [tasks, setTasks] = useState([]);
  const { logApiRequest, logApiResponse, logApiError, addLog } = useLog();

  // Base da API vinda do Vite
  // Exemplo:
  // VITE_API_URL="https://dev-bia.1labs.com.br"
  const API_BASE = (import.meta.env.VITE_API_URL || "").trim().replace(/\/$/, "");

  // Montador de URL
  // Exemplo:
  // apiUrl("/api/tarefas")
  // => https://dev-bia.1labs.com.br/api/tarefas
  const apiUrl = (path) => {
    const cleanPath = path.startsWith("/") ? path : `/${path}`;

    if (!API_BASE) {
      addLog(
        "WARN",
        "VITE_API_URL não definida",
        `Usando caminho relativo: ${cleanPath}`
      );
      return cleanPath;
    }

    return `${API_BASE}${cleanPath}`;
  };

  useEffect(() => {
    if (API_BASE) {
      addLog("INFO", "Aplicação iniciada", `API usando URL base: ${API_BASE}`);
    } else {
      addLog(
        "WARN",
        "Aplicação iniciada",
        "VITE_API_URL não definida. Usando caminho relativo."
      );
    }

    getTasks();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const getTasks = async () => {
    try {
      const tasksFromServer = await fetchTasks();
      setTasks(tasksFromServer);
    } catch (error) {
      addLog("ERROR", "Falha ao carregar tarefas", error.message);
    }
  };

  // Listar tarefas
  const fetchTasks = async () => {
    const url = apiUrl("/api/tarefas");
    logApiRequest("GET", url);

    try {
      const res = await fetch(url);
      const contentType = res.headers.get("content-type") || "";
      const data = contentType.includes("application/json")
        ? await res.json()
        : await res.text();

      logApiResponse("GET", url, res.status, data);

      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }

      if (typeof data === "string") {
        throw new Error("Resposta não-JSON recebida.");
      }

      return data;
    } catch (error) {
      logApiError("GET", url, error);
      throw error;
    }
  };

  // Buscar tarefa
  const fetchTask = async (uuid) => {
    const url = apiUrl(`/api/tarefas/${uuid}`);
    logApiRequest("GET", url);

    try {
      const res = await fetch(url);
      const contentType = res.headers.get("content-type") || "";
      const data = contentType.includes("application/json")
        ? await res.json()
        : await res.text();

      logApiResponse("GET", url, res.status, data);

      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }

      if (typeof data === "string") {
        throw new Error("Resposta não-JSON recebida.");
      }

      return data;
    } catch (error) {
      logApiError("GET", url, error);
      throw error;
    }
  };

  // Alternar prioridade
  const toggleReminder = async (uuid) => {
    try {
      const taskToToggle = await fetchTask(uuid);

      const updatedTask = {
        ...taskToToggle,
        importante: !taskToToggle.importante,
      };

      const url = apiUrl(`/api/tarefas/update_priority/${uuid}`);
      logApiRequest("PUT", url, updatedTask);

      const res = await fetch(url, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(updatedTask),
      });

      const contentType = res.headers.get("content-type") || "";
      const data = contentType.includes("application/json")
        ? await res.json()
        : await res.text();

      logApiResponse("PUT", url, res.status, data);

      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }

      if (typeof data === "string") {
        throw new Error("Resposta não-JSON recebida.");
      }

      setTasks(
        tasks.map((task) =>
          task.uuid === uuid ? { ...task, importante: data.importante } : task
        )
      );

      addLog(
        "SUCCESS",
        "Prioridade alterada",
        `Tarefa ${uuid} - Importante: ${data.importante}`
      );
    } catch (error) {
      addLog("ERROR", "Falha ao alterar prioridade", error.message);
    }
  };

  // Adicionar tarefa
  const addTask = async (task) => {
    const url = apiUrl("/api/tarefas");
    logApiRequest("POST", url, task);

    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(task),
      });

      const contentType = res.headers.get("content-type") || "";
      const data = contentType.includes("application/json")
        ? await res.json()
        : await res.text();

      logApiResponse("POST", url, res.status, data);

      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }

      if (typeof data === "string") {
        throw new Error("Resposta não-JSON recebida.");
      }

      setTasks([...tasks, data]);
      addLog("SUCCESS", "Tarefa criada", `"${task.titulo}" adicionada`);
    } catch (error) {
      logApiError("POST", url, error);
      addLog("ERROR", "Falha ao criar tarefa", error.message);
    }
  };

  // Remover tarefa
  const deleteTask = async (uuid) => {
    const url = apiUrl(`/api/tarefas/${uuid}`);
    logApiRequest("DELETE", url);

    try {
      const res = await fetch(url, { method: "DELETE" });
      logApiResponse("DELETE", url, res.status);

      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }

      setTasks(tasks.filter((task) => task.uuid !== uuid));
      addLog("SUCCESS", "Tarefa removida", `Tarefa ${uuid} excluída`);
    } catch (error) {
      logApiError("DELETE", url, error);
      addLog("ERROR", "Falha ao excluir tarefa", error.message);
    }
  };

  const HomePage = () => (
    <>
      <AddTask onAdd={addTask} />
      {tasks.length > 0 ? (
        <Tasks tasks={tasks} onDelete={deleteTask} onToggle={toggleReminder} />
      ) : (
        <div className="empty-state">
          <h3>Nenhuma tarefa por aqui 📝</h3>
          <p>Adicione sua primeira tarefa acima!</p>
        </div>
      )}
    </>
  );

  return (
    <div className="app">
      <Router>
        <div className="container">
          <Header />
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/about" element={<About />} />
          </Routes>
          <Footer />
        </div>
        <DebugLogs />
      </Router>
    </div>
  );
}

function App() {
  return (
    <ThemeProvider>
      <LogProvider>
        <AppContent />
      </LogProvider>
    </ThemeProvider>
  );
}

export default App;
