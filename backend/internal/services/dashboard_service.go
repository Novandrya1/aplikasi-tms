package services

import (
	"database/sql"
	"fmt"
	"strings"
	"time"
)

func GetNotifications(db *sql.DB, userID int, limit int) ([]map[string]interface{}, error) {
	query := `SELECT id, title, message, type, is_read, created_at
			  FROM notifications 
			  WHERE user_id = $1 
			  ORDER BY created_at DESC 
			  LIMIT $2`

	rows, err := db.Query(query, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get notifications: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer rows.Close()

	var notifications []map[string]interface{}
	for rows.Next() {
		var n map[string]interface{} = make(map[string]interface{})
		var id int
		var title, message, notifType string
		var isRead bool
		var createdAt time.Time

		err := rows.Scan(&id, &title, &message, &notifType, &isRead, &createdAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan notification: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		}

		n["id"] = id
		n["title"] = title
		n["message"] = message
		n["type"] = notifType
		n["is_read"] = isRead
		n["created_at"] = createdAt.Format("2006-01-02 15:04:05")

		notifications = append(notifications, n)
	}

	return notifications, nil
}

func MarkNotificationAsRead(db *sql.DB, notificationID int, userID int) error {
	query := `UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2`
	_, err := db.Exec(query, notificationID, userID)
	if err != nil {
		return fmt.Errorf("failed to mark notification as read: %v", err)
	}
	return nil
}

func GetVehicleTracking(db *sql.DB, fleetOwnerID int) ([]map[string]interface{}, error) {
	query := `SELECT vt.id, vt.vehicle_id, vt.latitude, vt.longitude, vt.speed, 
			  vt.status, vt.fuel_level, vt.mileage, vt.last_updated,
			  v.registration_number, v.brand, v.model
			  FROM vehicle_tracking vt
			  JOIN vehicles v ON vt.vehicle_id = v.id
			  WHERE v.fleet_owner_id = $1
			  ORDER BY vt.last_updated DESC`

	rows, err := db.Query(query, fleetOwnerID)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle tracking: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer rows.Close()

	var tracking []map[string]interface{}
	for rows.Next() {
		var t map[string]interface{} = make(map[string]interface{})
		var id, vehicleID int
		var latitude, longitude, speed, fuelLevel, mileage sql.NullFloat64
		var status, regNumber, brand, model string
		var lastUpdated time.Time

		err := rows.Scan(&id, &vehicleID, &latitude, &longitude, &speed,
			&status, &fuelLevel, &mileage, &lastUpdated, &regNumber, &brand, &model)
		if err != nil {
			return nil, fmt.Errorf("failed to scan tracking: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		}

		t["id"] = id
		t["vehicle_id"] = vehicleID
		t["registration_number"] = regNumber
		t["vehicle_name"] = fmt.Sprintf("%s %s", brand, model)
		t["status"] = status
		t["last_updated"] = lastUpdated.Format("2006-01-02 15:04:05")

		if latitude.Valid {
			t["latitude"] = latitude.Float64
		}
		if longitude.Valid {
			t["longitude"] = longitude.Float64
		}
		if speed.Valid {
			t["speed"] = speed.Float64
		}
		if fuelLevel.Valid {
			t["fuel_level"] = fuelLevel.Float64
		}
		if mileage.Valid {
			t["mileage"] = mileage.Float64
		}

		tracking = append(tracking, t)
	}

	return tracking, nil
}

func GetRevenueAnalytics(db *sql.DB, fleetOwnerID int, days int) (map[string]interface{}, error) {
	analytics := make(map[string]interface{})

	// Total revenue in period
	var totalRevenue, totalExpenses, totalProfit sql.NullFloat64
	query := `SELECT COALESCE(SUM(revenue), 0), COALESCE(SUM(expenses), 0), COALESCE(SUM(profit), 0)
			  FROM revenue_records 
			  WHERE fleet_owner_id = $1 AND trip_date >= CURRENT_DATE - INTERVAL $2`

	err := db.QueryRow(query, fleetOwnerID, fmt.Sprintf("%d days", days)).Scan(&totalRevenue, &totalExpenses, &totalProfit)
	if err != nil {
		return nil, fmt.Errorf("failed to get total revenue: %v", err)
	}

	analytics["total_revenue"] = totalRevenue.Float64
	analytics["total_expenses"] = totalExpenses.Float64
	analytics["total_profit"] = totalProfit.Float64

	// Daily revenue for chart
	dailyQuery := `SELECT trip_date, COALESCE(SUM(revenue), 0) as daily_revenue,
				   COALESCE(SUM(expenses), 0) as daily_expenses,
				   COALESCE(SUM(profit), 0) as daily_profit
				   FROM revenue_records 
				   WHERE fleet_owner_id = $1 AND trip_date >= CURRENT_DATE - INTERVAL $2
				   GROUP BY trip_date 
				   ORDER BY trip_date DESC`

	rows, err := db.Query(dailyQuery, fleetOwnerID, fmt.Sprintf("%d days", days))
	if err != nil {
		return nil, fmt.Errorf("failed to get daily revenue: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer rows.Close()

	var dailyData []map[string]interface{}
	for rows.Next() {
		var d map[string]interface{} = make(map[string]interface{})
		var tripDate time.Time
		var dailyRevenue, dailyExpenses, dailyProfit float64

		err := rows.Scan(&tripDate, &dailyRevenue, &dailyExpenses, &dailyProfit)
		if err != nil {
			return nil, fmt.Errorf("failed to scan daily revenue: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		}

		d["date"] = tripDate.Format("2006-01-02")
		d["revenue"] = dailyRevenue
		d["expenses"] = dailyExpenses
		d["profit"] = dailyProfit

		dailyData = append(dailyData, d)
	}

	analytics["daily_data"] = dailyData

	// Vehicle performance
	vehicleQuery := `SELECT v.registration_number, v.brand, v.model,
					 COALESCE(SUM(rr.revenue), 0) as vehicle_revenue,
					 COALESCE(SUM(rr.profit), 0) as vehicle_profit,
					 COUNT(rr.id) as trip_count
					 FROM vehicles v
					 LEFT JOIN revenue_records rr ON v.id = rr.vehicle_id 
					 AND rr.trip_date >= CURRENT_DATE - INTERVAL $2
					 WHERE v.fleet_owner_id = $1
					 GROUP BY v.id, v.registration_number, v.brand, v.model
					 ORDER BY vehicle_revenue DESC`

	vehicleRows, err := db.Query(vehicleQuery, fleetOwnerID, fmt.Sprintf("%d days", days))
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle performance: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer vehicleRows.Close()

	var vehiclePerformance []map[string]interface{}
	for vehicleRows.Next() {
		var v map[string]interface{} = make(map[string]interface{})
		var regNumber, brand, model string
		var vehicleRevenue, vehicleProfit float64
		var tripCount int

		err := vehicleRows.Scan(&regNumber, &brand, &model, &vehicleRevenue, &vehicleProfit, &tripCount)
		if err != nil {
			return nil, fmt.Errorf("failed to scan vehicle performance: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		}

		v["registration_number"] = regNumber
		v["vehicle_name"] = fmt.Sprintf("%s %s", brand, model)
		v["revenue"] = vehicleRevenue
		v["profit"] = vehicleProfit
		v["trip_count"] = tripCount

		vehiclePerformance = append(vehiclePerformance, v)
	}

	analytics["vehicle_performance"] = vehiclePerformance

	return analytics, nil
}

func CreateNotification(db *sql.DB, userID int, title, message, notifType string) error {
	query := `INSERT INTO notifications (user_id, title, message, type) VALUES ($1, $2, $3, $4)`
	_, err := db.Exec(query, userID, title, message, notifType)
	if err != nil {
		return fmt.Errorf("failed to create notification: %v", err)
	}
	return nil
}