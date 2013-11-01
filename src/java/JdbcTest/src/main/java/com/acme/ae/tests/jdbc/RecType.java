package com.acme.ae.tests.jdbc;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.STRUCT;
import oracle.jpub.runtime.MutableStruct;

public class RecType implements ORAData, ORADataFactory
{
  public static final String _SQL_NAME = "AIS.AE_STATE_REC";
  public static final int _SQL_TYPECODE = OracleTypes.STRUCT;

  protected MutableStruct _struct;

  protected static int[] _sqlType =  { 2,2,2,12,12 };
  protected static ORADataFactory[] _factory = new ORADataFactory[5];
  protected static final RecType _AeStateRecFactory = new RecType();

  public static ORADataFactory getORADataFactory()
  { return _AeStateRecFactory; }
  /* constructors */
  protected void _init_struct(boolean init)
  { if (init) _struct = new MutableStruct(new Object[5], _sqlType, _factory); }
  public RecType()
  { _init_struct(true); }
  public RecType(oracle.sql.NUMBER deviceId, oracle.sql.NUMBER profileId, oracle.sql.NUMBER paramId, oracle.sql.CHAR num, oracle.sql.CHAR value) throws SQLException
  { _init_struct(true);
    setDeviceId(deviceId);
    setProfileId(profileId);
    setParamId(paramId);
    setNum(num);
    setValue(value);
  }

  /* ORAData interface */
  public Datum toDatum(Connection c) throws SQLException
  {
    return _struct.toDatum(c, _SQL_NAME);
  }


  /* ORADataFactory interface */
  public ORAData create(Datum d, int sqlType) throws SQLException
  { return create(null, d, sqlType); }
  protected ORAData create(RecType o, Datum d, int sqlType) throws SQLException
  {
    if (d == null) return null; 
    if (o == null) o = new RecType();
    o._struct = new MutableStruct((STRUCT) d, _sqlType, _factory);
    return o;
  }
  /* accessor methods */
  public oracle.sql.NUMBER getDeviceId() throws SQLException
  { return (oracle.sql.NUMBER) _struct.getOracleAttribute(0); }

  public void setDeviceId(oracle.sql.NUMBER deviceId) throws SQLException
  { _struct.setOracleAttribute(0, deviceId); }


  public oracle.sql.NUMBER getProfileId() throws SQLException
  { return (oracle.sql.NUMBER) _struct.getOracleAttribute(1); }

  public void setProfileId(oracle.sql.NUMBER profileId) throws SQLException
  { _struct.setOracleAttribute(1, profileId); }


  public oracle.sql.NUMBER getParamId() throws SQLException
  { return (oracle.sql.NUMBER) _struct.getOracleAttribute(2); }

  public void setParamId(oracle.sql.NUMBER paramId) throws SQLException
  { _struct.setOracleAttribute(2, paramId); }


  public oracle.sql.CHAR getNum() throws SQLException
  { return (oracle.sql.CHAR) _struct.getOracleAttribute(3); }

  public void setNum(oracle.sql.CHAR num) throws SQLException
  { _struct.setOracleAttribute(3, num); }


  public oracle.sql.CHAR getValue() throws SQLException
  { return (oracle.sql.CHAR) _struct.getOracleAttribute(4); }

  public void setValue(oracle.sql.CHAR value) throws SQLException
  { _struct.setOracleAttribute(4, value); }

}
