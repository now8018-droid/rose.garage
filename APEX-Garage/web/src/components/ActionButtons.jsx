export default function ActionButtons({ onAction }) {
  return (
    <div className="action-buttons">
      <button type="button" onClick={() => onAction('tankCar')}>Tanken</button>
      <button type="button" onClick={() => onAction('openTrunk')}>Kofferraum</button>
      <button type="button" className="drive" onClick={() => onAction('driveCar')}>Drive Car</button>
    </div>
  );
}
