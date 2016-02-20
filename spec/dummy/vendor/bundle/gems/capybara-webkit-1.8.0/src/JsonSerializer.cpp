#include "JsonSerializer.h"
#include <cmath>

JsonSerializer::JsonSerializer(QObject *parent) : QObject(parent) {
}

QByteArray JsonSerializer::serialize(const QVariant &object) {
  addVariant(object);
  return m_buffer;
}

void JsonSerializer::addVariant(const QVariant &object) {
  if (object.isValid()) {
    switch(object.type()) {
      case QMetaType::QString:
        {
          QString string = object.toString();
          addString(string);
        }
        break;
      case QMetaType::QVariantList:
        {
          QVariantList list = object.toList();
          addArray(list);
        }
        break;
      case QMetaType::Double:
        if (std::isinf(object.toDouble()))
          m_buffer.append("null");
        else
          m_buffer.append(object.toString());
        break;
      case QMetaType::QVariantMap:
        {
          QVariantMap map = object.toMap();
          addMap(map);
          break;
        }
      case QMetaType::Bool:
        {
          m_buffer.append(object.toString());
          break;
        }
      case QMetaType::Int:
        {
          m_buffer.append(object.toString());
          break;
        }
      default:
        m_buffer.append("null");
    }
  } else {
    m_buffer.append("null");
  }
}

void JsonSerializer::addString(const QString &string) {
  m_buffer.append("\"");
  m_buffer.append(sanitizeString(string));
  m_buffer.append("\"");
}

void JsonSerializer::addArray(const QVariantList &list) {
  m_buffer.append("[");
  for (int i = 0; i < list.length(); i++) {
    if (i > 0)
      m_buffer.append(",");
    addVariant(list[i]);
  }
  m_buffer.append("]");
}

void JsonSerializer::addMap(const QVariantMap &map) {
  m_buffer.append("{");
  QMapIterator<QString, QVariant> iterator(map);
  while (iterator.hasNext()) {
    iterator.next();
    QString key = iterator.key();
    QVariant value = iterator.value();
    addString(key);
    m_buffer.append(":");
    addVariant(value);
    if (iterator.hasNext())
      m_buffer.append(",");
  }
  m_buffer.append("}");
}

QByteArray JsonSerializer::sanitizeString(QString str) {
  str.replace("\\", "\\\\");
  str.replace("\"", "\\\"");
  str.replace("\b", "\\b");
  str.replace("\f", "\\f");
  str.replace("\n", "\\n");
  str.replace("\r", "\\r");
  str.replace("\t", "\\t");

  QByteArray result;
  const ushort* unicode = str.utf16();
  unsigned int i = 0;

  while (unicode[i]) {
    if (unicode[i] > 31 && unicode[i] < 128) {
      result.append(unicode[i]);
    }
    else {
      QString hexCode = QString::number(unicode[i], 16).rightJustified(4, '0');

      result.append("\\u").append(hexCode);
    }
    ++i;
  }

  return result;
}

