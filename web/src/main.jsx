import React from 'react'
import { createRoot } from 'react-dom/client'
import './styles.css'
import { useEffect, useMemo, useState } from 'react'

const RESOURCE_NAME = 'APEX-Garage'
const getResource = () => {
  if (typeof window.GetParentResourceName === 'function') return window.GetParentResourceName()
  return RESOURCE_NAME
}

const nuiPost = (endpoint, payload = {}) => {
  return fetch(`https://${getResource()}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  })
}

const clamp = (n, min = 0, max = 100) => Math.max(min, Math.min(max, Number(n) || 0))

function App() {
  const [visible, setVisible] = useState(false)
  const [garageType, setGarageType] = useState('garage')
  const [cars, setCars] = useState([])
  const [selectedPlate, setSelectedPlate] = useState('')
  const [query, setQuery] = useState('')
  const [parkFilter, setParkFilter] = useState('all')
  const [pounddeposit, setPounddeposit] = useState(false)
  const [spawnProgress, setSpawnProgress] = useState({ show: false, duration: 0, plate: '', pct: 0 })

  useEffect(() => {
    const timerRef = { id: null }
    const onMessage = (event) => {
      const data = event.data || {}
      if (data.action === 'open') setVisible(true)
      if (data.action === 'closeui') {
        setVisible(false)
        setSpawnProgress({ show: false, duration: 0, plate: '', pct: 0 })
      }
      if (data.action === 'pounddeposit') setPounddeposit(Boolean(data.pounddeposit))
      if (data.action === 'syncData') {
        const incoming = Array.isArray(data.data) ? data.data : []
        setGarageType(data.type || 'garage')
        setCars(incoming)
        if (!incoming.some((c) => c.plate === selectedPlate)) {
          setSelectedPlate(incoming[0]?.plate || '')
        }
      }
      if (data.action === 'spawnProgress') {
        const next = { show: Boolean(data.show), duration: Number(data.duration) || 0, plate: data.plate || '', pct: 0 }
        setSpawnProgress(next)
        if (timerRef.id) clearInterval(timerRef.id)
        if (next.show) {
          const started = Date.now()
          timerRef.id = setInterval(() => {
            const pct = clamp(Math.floor(((Date.now() - started) / Math.max(1, next.duration)) * 100))
            setSpawnProgress((prev) => ({ ...prev, pct }))
            if (pct >= 100) {
              clearInterval(timerRef.id)
              timerRef.id = null
            }
          }, 50)
        }
      }
    }

    window.addEventListener('message', onMessage)
    return () => {
      window.removeEventListener('message', onMessage)
      if (timerRef.id) clearInterval(timerRef.id)
    }
  }, [selectedPlate])

  useEffect(() => {
    const onEsc = (e) => {
      if (e.key === 'Escape' && visible) {
        nuiPost('exit', { plate: '' })
      }
    }
    window.addEventListener('keyup', onEsc)
    return () => window.removeEventListener('keyup', onEsc)
  }, [visible])

  const mappedCars = useMemo(() => {
    return cars.map((car) => {
      let state = 'pound'
      if (pounddeposit) {
        if (car.stored && !car.deposit) state = 'garage'
      } else if (car.stored) {
        state = 'garage'
      }
      return { ...car, state }
    })
  }, [cars, pounddeposit])

  const filteredCars = useMemo(() => {
    return mappedCars.filter((car) => {
      if (parkFilter !== 'all' && car.state !== parkFilter) return false
      if (!query) return true
      return `${car.vehiclename || ''} ${car.plate || ''}`.toLowerCase().includes(query.toLowerCase())
    })
  }, [mappedCars, parkFilter, query])

  const selected = useMemo(() => mappedCars.find((c) => c.plate === selectedPlate) || filteredCars[0], [mappedCars, filteredCars, selectedPlate])

  useEffect(() => {
    if (!selectedPlate && filteredCars[0]?.plate) setSelectedPlate(filteredCars[0].plate)
  }, [filteredCars, selectedPlate])

  const handleSpawn = (plate) => nuiPost('spawnvehicle', { plate })
  const handleTrunk = (plate) => nuiPost('trunkopen', { plate })
  const handleShare = (plate) => nuiPost('sendvehicle', { plate })

  if (!visible) return null

  return (
    <div className="page">
      <div className="overlay-noise" />
      <div className="layout">
        <section className="left-panel panel">
          <header className="top-row">
            <div>
              <p className="eyebrow">• GARAGE</p>
              <h1>TRACER<span className="muted">replay</span></h1>
            </div>
            <button className="close" onClick={() => nuiPost('exit', { plate: '' })}>CLOSE ✕</button>
          </header>

          <div className="toolbar">
            <div className="park-toggle">
              <button className={parkFilter === 'all' ? 'active' : ''} onClick={() => setParkFilter('all')}>All</button>
              <button className={parkFilter === 'garage' ? 'active' : ''} onClick={() => setParkFilter('garage')}>Parked</button>
              <button className={parkFilter === 'pound' ? 'active' : ''} onClick={() => setParkFilter('pound')}>Pound</button>
            </div>
            <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search car..." />
          </div>

          <div className="grid">
            {filteredCars.map((car) => (
              <article key={car.plate} className={`car-card ${selected?.plate === car.plate ? 'selected' : ''}`} onClick={() => setSelectedPlate(car.plate)}>
                <span className="class">{car.class || 'Unknown'}</span>
                <button className="star">☆</button>
                <h3>{car.vehiclename || car.modelname || 'UNKNOWN'}</h3>
                <img src={`img/${car.img}.png`} alt={car.vehiclename || car.modelname || 'vehicle'} onError={(e) => { e.currentTarget.src = 'img/model_car1.png' }} />
                {spawnProgress.show && spawnProgress.plate === car.plate ? <div className="progress">{spawnProgress.pct}%</div> : null}
                <button className="select" onClick={(e) => { e.stopPropagation(); handleSpawn(car.plate) }}>• select car</button>
              </article>
            ))}
          </div>
        </section>

        <aside className="right-panel panel">
          {selected ? (
            <>
              <p className="eyebrow">• Selected Car •</p>
              <h2>{selected.vehiclename || selected.modelname || 'UNKNOWN'} /</h2>
              <img className="hero" src={`img/${selected.img}.png`} alt={selected.vehiclename || selected.modelname || 'car'} onError={(e) => { e.currentTarget.src = 'img/model_car2.png' }} />
              <div className="plate">{selected.plate}</div>
              <div className="owner">Felx Haffner</div>
              <button className="share" onClick={() => handleShare(selected.plate)}>↗ Share Car</button>

              <div className="stats">
                <Stat name="Fuelstatus" value={`${clamp(selected.fuel)}L`} pct={clamp(selected.fuel)} />
                <Stat name="Trunkspace" value="150 /500" pct={30} />
                <Stat name="Enginestatus" value={`${clamp(selected.engine)}%`} pct={clamp(selected.engine)} />
              </div>

              <div className="actions">
                <button onClick={() => handleTrunk(selected.plate)}>✕ Trunk Car</button>
                <button onClick={() => nuiPost('reloadVehicleData', {})}>◉ Fuel Car</button>
                <button onClick={() => handleSpawn(selected.plate)}>➤ Drive Car</button>
              </div>
            </>
          ) : <div className="empty">No vehicle data</div>}
        </aside>
      </div>
      <div className="bg" data-type={garageType} />
    </div>
  )
}

function Stat({ name, value, pct }) {
  return (
    <div className="stat">
      <div>
        <strong>{name}</strong>
        <small>Some short information</small>
      </div>
      <div className="track"><span style={{ width: `${clamp(pct)}%` }} /></div>
      <span className="chip">{value}</span>
    </div>
  )
}

createRoot(document.getElementById('root')).render(<App />)
