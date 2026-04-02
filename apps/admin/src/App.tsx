import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import LoginPage from './pages/LoginPage'
import DashboardShell from './pages/DashboardShell'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/*" element={<DashboardShell />} />
        <Route path="/" element={<Navigate to="/disputes" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
