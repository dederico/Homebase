import React, { useState, useEffect } from 'react';
import './App.css'; 

const App = () => {
  const [data, setData] = useState({ employees: [], daily_totals: {} });
  const [sortOption, setSortOption] = useState('first_name');
  const [shiftPlanData, setShiftPlanData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);


  useEffect(() => {
    setIsLoading(true);
    fetch(`/shifts?sort_by=${sortOption}`)
      .then(response => response.json())
      .then(data => {
        console.log('Fetched data:', data);
        setData(data);
        setShiftPlanData(data.shift_plan_data);
        setIsLoading(false);
      })
      .catch(error => {
        console.error('Error fetching data:', error);
        setIsLoading(false);
      });
  }, [sortOption]);

  const handleSortChange = e => {
    setSortOption(e.target.value);
  };

  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  const uniqueDays = Array.from(new Set(data.employees.flatMap(employee => employee.shifts.map(shift => shift.day))));
  
  const sortedDays = uniqueDays.sort((a, b) => a - b);

  const dailyTotals = {};
  data.employees.forEach(employee => {
    employee.shifts.forEach(shift => {
      const day = shift.day;
      const duration = shift.duration;
      dailyTotals[day] = (dailyTotals[day] || 0) + duration;
    });
  });

  if (isLoading) {
    return <div>Loading...</div>;
  }

  const parseGeneratedMessage = () => {
    // Extract the relevant information from the generated message
    const lines = shiftPlanData.generated_message.split('\n');
    const employeeLines = lines.slice(2, lines.length - 1); // Exclude first and last lines
  
    const employeeHours = {};
    employeeLines.forEach(line => {
      const match = line.match(/- (.+): (.+) \(.+ hours\)/);
      if (match) {
        const employeeName = match[1];
        const hours = parseInt(match[2], 10);
        employeeHours[employeeName] = hours;
      }
    });
  
    return employeeHours;
  };

  const employeeHours = parseGeneratedMessage();


  return (
    <div>
      <label>
        Sort by:
        <select value={sortOption} onChange={handleSortChange}>
          <option value="first_name">First Name</option>
          <option value="last_name">Last Name</option>
        </select>
      </label>

      <table>
        <thead>
          <tr>
            <th>Employee</th>
            {sortedDays.map((day, index) => (
              <th key={index}>
                {dayNames[day]}
                <div>Total: {dailyTotals[day] || 0}</div>
              </th>
            ))}
            <th>Weekly Total</th>
          </tr>
        </thead>
        <tbody>
          {data.employees.map(employee => (
            <tr key={employee.name}>
              <td>{employee.name}</td>
              {sortedDays.map(day => {
                const total = employee.daily_totals[day] || 0;
                const shift = employee.shifts.find(s => s.day === day);
                const cellStyle = {
                  backgroundColor: shift && total > 0 ? shift.color : 'transparent',
                  color: 'white',
                  textAlign: 'center',
                  padding: '5px',
                };
                return (
                  <td key={day} style={cellStyle}>
                    <div>{total}</div>
                    {shift && <div>{shift.role}</div>}
                  </td>
                );
              })}
              <td>{employee.weekly_total}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {shiftPlanData && (
      <div>
        <h2>Generated Shift Plan</h2>
        <p>{shiftPlanData.generated_message}</p>
      </div>
    )}
    </div>
  );
};

export default App;
