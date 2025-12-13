import React from 'react'
import ArchitectureDiagram from './components/ArchitectureDiagram'
import RoutingTest from './components/RoutingTest'
import RegionCard from './components/RegionCard'
import IdcCard from './components/IdcCard'
import TestLogger from './components/TestLogger'

export default function App() {
  return (
    <div className="dashboard">
      <header className="header">
        <h1>Infra Test Dashboard</h1>
        <p className="subtitle">
          AWS Multi-Region (Seoul/Tokyo) + IDC VPN Connection Test
        </p>
      </header>

      <section className="section">
        <ArchitectureDiagram />
      </section>

      <section className="section">
        <RoutingTest />
      </section>

      <section className="section">
        <h2 className="section-title">Individual Tests</h2>
        <div className="cards-container">
          <RegionCard />
          <IdcCard />
        </div>
      </section>

      <section className="section">
        <TestLogger />
      </section>
    </div>
  )
}
