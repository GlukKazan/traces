package com.acme.ae.tests.jdbc;

import oracle.jdbc.driver.OracleCallableStatement;
import oracle.sql.*;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Test {
	
	private final static String CLASS_NAME = "oracle.jdbc.driver.OracleDriver";
	private final static String USER_CONN  = "jdbc:oracle:thin:@192.168.124.5:1523:new11";
	private final static String USER_NAME  = "ais";
	private final static String USER_PASS  = "ais";
	
	private final static boolean AUTO_COMMIT_MODE = false;
	private final static int     BULK_SIZE        = 200;
	private final static int     ALL_SIZE         = 1000;

	private final static String  TRACE_ON_SQL     =
			"ALTER SESSION SET EVENTS '10046 trace name context forever, level 12'";
	
	private final static String  INS_VAL_SQL      =
			"insert into ae_state_tmp(id, device_id, profile_id, param_id, num, value) values (?,?,?,?,?,?)";
	
	private final static String  MERGE_VAL_SQL    =
			"merge into ae_state_tmp d " +
			"using ( select ? id,? device_id,? profile_id,? param_id,? num,? value " +
			"        from dual" +
			"      ) s " +
			"on ( d.device_id = s.device_id and d.profile_id = s.profile_id and " +
			"     d.param_id = s.param_id and d.num = s.num ) " +
			"when matched then " +
			"  update set d.value = s.value " +
			"when not matched then " +
			"  insert (id, device_id, profile_id, param_id, num, value) " +
			"  values (s.id, s.device_id, s.profile_id, s.param_id, s.num, s.value)";

	private final static String  SAVE_VALUES_SQL  = 
			"begin ae_monitoring.saveValues; end;";
	
	private final static String  SAVE_VALUES_DISTINCT_SQL  = 
			"begin ae_monitoring.saveValuesDistinct; end;";

	private final static String  ADD_VAL_SQL      = 
			"begin ae_monitoring.addValue(?,?,?,?,?); end;";
	
	private final static String  ADD_VALUES_SQL   = 
			"begin ae_monitoring.addValues(?); end;";

	private final static String  BULK_VALUES_SQL  = 
			"begin ae_monitoring.saveValues(?); end;";
	
	private final static Long   DEVICE_ID         = 0L;
	private final static Long   PROFILE_ID        = 1L;
	private final static Long   UPTIME_PARAM_ID   = 101L;
	private final static Long   IFNAME_PARAM_ID   = 103L;
	private final static Long   INOCT_PARAM_ID    = 104L;
	private final static String FAKE_NUM_VALUE    = "0";
	
	private Connection c = null;
	
	private void test_plsql() throws SQLException {
		System.out.println("test_plsql:");
		CallableStatement st = c.prepareCall(ADD_VAL_SQL);
		Long timestamp = System.currentTimeMillis();
		Long uptime = 0L;
		Long inoct  = 0L;
		try {
			for (int i = 1; i <= ALL_SIZE; i++) {
				
				// Передать uptime
				st.setLong(1,   DEVICE_ID);
				st.setLong(2,   PROFILE_ID);
				st.setLong(3,   UPTIME_PARAM_ID);
				st.setString(4, FAKE_NUM_VALUE);
				st.setString(5, uptime.toString());
				st.execute();
				
				// Передать имя интерфейса
				st.setLong(1,   DEVICE_ID);
				st.setLong(2,   PROFILE_ID);
				st.setLong(3,   IFNAME_PARAM_ID);
				st.setString(4, Integer.toString((i % 100) + 1));
				st.setString(5, Integer.toString((i % 100) + 1));
				st.execute();
				
				// Передать счетчик трафика
				st.setLong(1,   DEVICE_ID);
				st.setLong(2,   PROFILE_ID);
				st.setLong(3,   INOCT_PARAM_ID);
				st.setString(4, Integer.toString((i % 100) + 1));
				st.setString(5, inoct.toString());
				st.execute();

				// Увеличить счетчики
				uptime += 100L;
				if (uptime >= 1000) {
					uptime = 0L;
				}
				inoct += 10L;
			}
		} finally {
			st.close();
		}
		Long delta_1 = System.currentTimeMillis() - timestamp;
		System.out.println((ALL_SIZE * 1000L) / delta_1);
		timestamp = System.currentTimeMillis();
		c.commit();
		Long delta_2 = System.currentTimeMillis() - timestamp;
		System.out.println(delta_2);
		System.out.println((ALL_SIZE * 1000L) / (delta_1 - delta_2));
	}
	
	private void test_temporary() throws SQLException {
		System.out.println("test_temporary:");
		CallableStatement st = c.prepareCall(MERGE_VAL_SQL);
		Long timestamp = System.currentTimeMillis();
		Long uptime = 0L;
		Long inoct  = 0L;
		Long ix     = 1L;
		int  bulk   = BULK_SIZE; 
		try {
			for (int i = 1; i <= ALL_SIZE; i++) {
			
				// Передать uptime
				st.setLong(1,   ix++);
				st.setLong(2,   DEVICE_ID);
				st.setLong(3,   PROFILE_ID);
				st.setLong(4,   UPTIME_PARAM_ID);
				st.setString(5, FAKE_NUM_VALUE);
				st.setString(6, uptime.toString());
				st.addBatch();
				
				// Передать имя интерфейса
				st.setLong(1,   ix++);
				st.setLong(2,   DEVICE_ID);
				st.setLong(3,   PROFILE_ID);
				st.setLong(4,   IFNAME_PARAM_ID);
				st.setString(5, Integer.toString((i % 100) + 1));
				st.setString(6, Integer.toString((i % 100) + 1));
				st.addBatch();
				
				// Передать счетчик трафика
				st.setLong(1,   ix++);
				st.setLong(2,   DEVICE_ID);
				st.setLong(3,   PROFILE_ID);
				st.setLong(4,   INOCT_PARAM_ID);
				st.setString(5, Integer.toString((i % 100) + 1));
				st.setString(6, inoct.toString());
				st.addBatch();
				
				if (--bulk <= 0) {
					st.executeBatch();
					bulk = BULK_SIZE;
				}
			
				// Увеличить счетчики
				uptime += 100L;
				if (uptime >= 1000) {
					uptime = 0L;
				}
				inoct += 10L;
			}
			if (bulk < BULK_SIZE) {
				st.executeBatch();
			}
		} finally {
			st.close();
		}
		Long delta_1 = System.currentTimeMillis() - timestamp;
		System.out.println((ALL_SIZE * 1000L) / delta_1);
		timestamp = System.currentTimeMillis();
		st = c.prepareCall(SAVE_VALUES_SQL);
		timestamp = System.currentTimeMillis();
		try {
			st.execute();
		} finally {
			st.close();
		}
		Long delta_2 = System.currentTimeMillis() - timestamp;
		System.out.println(delta_2);
		System.out.println((ALL_SIZE * 1000L) / (delta_1 - delta_2));
	}
	
	private void test_temporary_distinct() throws SQLException {
		System.out.println("test_temporary:");
		CallableStatement st = c.prepareCall(INS_VAL_SQL);
		Long timestamp = System.currentTimeMillis();
		Long uptime = 0L;
		Long inoct  = 0L;
		Long ix     = 1L;
		int  bulk   = BULK_SIZE; 
		try {
			for (int i = 1; i <= ALL_SIZE; i++) {
			
				// Передать uptime
				st.setLong(1,   ix++);
				st.setLong(2,   DEVICE_ID);
				st.setLong(3,   PROFILE_ID);
				st.setLong(4,   UPTIME_PARAM_ID);
				st.setString(5, FAKE_NUM_VALUE);
				st.setString(6, uptime.toString());
				st.addBatch();
				
				// Передать имя интерфейса
				st.setLong(1,   ix++);
				st.setLong(2,   DEVICE_ID);
				st.setLong(3,   PROFILE_ID);
				st.setLong(4,   IFNAME_PARAM_ID);
				st.setString(5, Integer.toString((i % 100) + 1));
				st.setString(6, Integer.toString((i % 100) + 1));
				st.addBatch();
				
				// Передать счетчик трафика
				st.setLong(1,   ix++);
				st.setLong(2,   DEVICE_ID);
				st.setLong(3,   PROFILE_ID);
				st.setLong(4,   INOCT_PARAM_ID);
				st.setString(5, Integer.toString((i % 100) + 1));
				st.setString(6, inoct.toString());
				st.addBatch();
				
				if (--bulk <= 0) {
					st.executeBatch();
					bulk = BULK_SIZE;
				}
			
				// Увеличить счетчики
				uptime += 100L;
				if (uptime >= 1000) {
					uptime = 0L;
				}
				inoct += 10L;
			}
			if (bulk < BULK_SIZE) {
				st.executeBatch();
			}
		} finally {
			st.close();
		}
		Long delta_1 = System.currentTimeMillis() - timestamp;
		System.out.println((ALL_SIZE * 1000L) / delta_1);
		timestamp = System.currentTimeMillis();
		st = c.prepareCall(SAVE_VALUES_DISTINCT_SQL);
		timestamp = System.currentTimeMillis();
		try {
			st.execute();
		} finally {
			st.close();
		}
		Long delta_2 = System.currentTimeMillis() - timestamp;
		System.out.println(delta_2);
		System.out.println((ALL_SIZE * 1000L) / (delta_1 - delta_2));
	}
	
	private void test_collection() throws SQLException {
		System.out.println("test_collection:");
		OracleCallableStatement st = (OracleCallableStatement)c.prepareCall(ADD_VALUES_SQL);
		int oracleId = CharacterSet.CL8MSWIN1251_CHARSET;
		CharacterSet charSet = CharacterSet.make(oracleId);		
		Long timestamp = System.currentTimeMillis();
		Long uptime = 0L;
		Long inoct  = 0L;
		RecType r[] = new RecType[ALL_SIZE * 3]; 
		int ix      = 0;
		for (int i = 1; i <= ALL_SIZE; i++) {

			// Передать uptime
			r[ix++] = new RecType(
					new NUMBER(DEVICE_ID),
					new NUMBER(PROFILE_ID),
					new NUMBER(UPTIME_PARAM_ID),
					new CHAR(FAKE_NUM_VALUE, charSet),
					new CHAR(uptime.toString(), charSet));
			
			// Передать имя интерфейса
			r[ix++] = new RecType(
					new NUMBER(DEVICE_ID),
					new NUMBER(PROFILE_ID),
					new NUMBER(IFNAME_PARAM_ID),
					new CHAR(Integer.toString((i % 100) + 1), charSet),
					new CHAR(Integer.toString((i % 100) + 1), charSet));
			
			// Передать счетчик трафика
			r[ix++] = new RecType(
					new NUMBER(DEVICE_ID),
					new NUMBER(PROFILE_ID),
					new NUMBER(INOCT_PARAM_ID),
					new CHAR(Integer.toString((i % 100) + 1), charSet),
					new CHAR(inoct.toString(), charSet));
		
			// Увеличить счетчики
			uptime += 100L;
			if (uptime >= 1000) {
				uptime = 0L;
			}
			inoct += 10L;
		}
		RecTab t = new RecTab(r);
		try {
			st.setORAData(1, t);
//			st.registerOutParameter(1, OracleTypes.ARRAY, "AE_STATE_TAB");
			st.execute();
		} finally {
			st.close();
		}
		System.out.println((ALL_SIZE * 1000L) / (System.currentTimeMillis() - timestamp));
	}
	
	private void test_bulk() throws SQLException {
		System.out.println("test_bulk:");
		OracleCallableStatement st = (OracleCallableStatement)c.prepareCall(BULK_VALUES_SQL);
		int oracleId = CharacterSet.CL8MSWIN1251_CHARSET;
		CharacterSet charSet = CharacterSet.make(oracleId);		
		Long timestamp = System.currentTimeMillis();
		Long uptime = 0L;
		Long inoct  = 0L;
		RecType r[] = new RecType[ALL_SIZE * 3]; 
		int ix      = 0;
		for (int i = 1; i <= ALL_SIZE; i++) {

			// Передать uptime
			r[ix++] = new RecType(
					new NUMBER(DEVICE_ID),
					new NUMBER(PROFILE_ID),
					new NUMBER(UPTIME_PARAM_ID),
					new CHAR(FAKE_NUM_VALUE, charSet),
					new CHAR(uptime.toString(), charSet));
			
			// Передать имя интерфейса
			r[ix++] = new RecType(
					new NUMBER(DEVICE_ID),
					new NUMBER(PROFILE_ID),
					new NUMBER(IFNAME_PARAM_ID),
					new CHAR(Integer.toString((i % 100) + 1), charSet),
					new CHAR(Integer.toString((i % 100) + 1), charSet));
			
			// Передать счетчик трафика
			r[ix++] = new RecType(
					new NUMBER(DEVICE_ID),
					new NUMBER(PROFILE_ID),
					new NUMBER(INOCT_PARAM_ID),
					new CHAR(Integer.toString((i % 100) + 1), charSet),
					new CHAR(inoct.toString(), charSet));
		
			// Увеличить счетчики
			uptime += 100L;
			if (uptime >= 1000) {
				uptime = 0L;
			}
			inoct += 10L;
		}
		RecTab t = new RecTab(r);
		try {
			st.setORAData(1, t);
//			st.registerOutParameter(1, OracleTypes.ARRAY, "AE_STATE_TAB");
			st.execute();
		} finally {
			st.close();
		}
		System.out.println((ALL_SIZE * 1000L) / (System.currentTimeMillis() - timestamp));
	}
	
	private void start() throws ClassNotFoundException, SQLException {
		Class.forName(CLASS_NAME);
		c = DriverManager.getConnection(USER_CONN, USER_NAME, USER_PASS);
		c.setAutoCommit(AUTO_COMMIT_MODE);
		CallableStatement st = c.prepareCall(TRACE_ON_SQL);
		try {
			st.execute();
		} finally {
			st.close();
		}
	}
	
	private void stop() throws SQLException  {
		if (c != null) {
			c.close();
		}
	}

	public static void main(String[] args) {
		Test t = new Test();
		try {
			try {
				t.start();
//				t.test_plsql();
				t.test_temporary();
//				t.test_temporary_distinct();
//				t.test_collection();
//				t.test_bulk();
			} finally {
				t.stop();
			}
		} catch (Exception e) {
			System.out.println(e.toString());
		}
	}
}
