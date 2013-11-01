package com.acme.ae.tests.jdbc;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.ARRAY;
import oracle.sql.ArrayDescriptor;
import oracle.jpub.runtime.MutableArray;

public class RecTab implements ORAData, ORADataFactory
{
  public static final String _SQL_NAME = "AIS.AE_STATE_TAB";
  public static final int _SQL_TYPECODE = OracleTypes.ARRAY;

  MutableArray _array;

private static final RecTab _ae_state_tabFactory = new RecTab();

  public static ORADataFactory getORADataFactory()
  { return _ae_state_tabFactory; }
  /* constructors */
  public RecTab()
  {
    this((RecType[])null);
  }

  public RecTab(RecType[] a)
  {
    _array = new MutableArray(2002, a, RecType.getORADataFactory());
  }

  /* ORAData interface */
  public Datum toDatum(Connection c) throws SQLException
  {
    return _array.toDatum(c, _SQL_NAME);
  }

  /* ORADataFactory interface */
  public ORAData create(Datum d, int sqlType) throws SQLException
  {
    if (d == null) return null; 
    RecTab a = new RecTab();
    a._array = new MutableArray(2002, (ARRAY) d, RecType.getORADataFactory());
    return a;
  }

  public int length() throws SQLException
  {
    return _array.length();
  }

  public int getBaseType() throws SQLException
  {
    return _array.getBaseType();
  }

  public String getBaseTypeName() throws SQLException
  {
    return _array.getBaseTypeName();
  }

  public ArrayDescriptor getDescriptor() throws SQLException
  {
    return _array.getDescriptor();
  }

  /* array accessor methods */
  public RecType[] getArray() throws SQLException
  {
    return (RecType[]) _array.getObjectArray(
      new RecType[_array.length()]);
  }

  public RecType[] getArray(long index, int count) throws SQLException
  {
    return (RecType[]) _array.getObjectArray(index,
      new RecType[_array.sliceLength(index, count)]);
  }

  public void setArray(RecType[] a) throws SQLException
  {
    _array.setObjectArray(a);
  }

  public void setArray(RecType[] a, long index) throws SQLException
  {
    _array.setObjectArray(a, index);
  }

  public RecType getElement(long index) throws SQLException
  {
    return (RecType) _array.getObjectElement(index);
  }

  public void setElement(RecType a, long index) throws SQLException
  {
    _array.setObjectElement(a, index);
  }

}
