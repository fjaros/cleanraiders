package cleanraiders.parser;

import java.util.Iterator;
import java.util.List;

class SheetParser {

    private final StringBuilder sb = new StringBuilder();

    interface RowParser<T> {
        void parseRows(T rows);
    }

    private class RaidNameParser implements RowParser<List<List<List<Object>>>> {

        private int onRaid = 1;

        @Override
        public void parseRows(List<List<List<Object>>> rows) {
            for (List<List<Object>> sheet : rows) {
                Iterator<List<Object>> iter = sheet.iterator();
                while (iter.hasNext()) {
                    List<Object> row = iter.next();
                    if (isBlankRow(row)) {
                        continue;
                    }
                    beginMap(onRaid++);
                    addGridEntry(1, row.get(0));
                    new EncounterNameParser().parseRows(iter);
                    endMap();
                }
            }
        }
    }

    private class EncounterNameParser implements RowParser<Iterator<List<Object>>> {

        private int onEncounter = 1;

        @Override
        public void parseRows(Iterator<List<Object>> rows) {
            while (rows.hasNext()) {
                List<Object> row = rows.next();
                if (isBlankRow(row)) {
                    continue;
                }
                beginMap(++onEncounter);
                new EncounterParser(row).parseRows(rows);
                endMap();
            }
        }
    }

    private class EncounterParser implements RowParser<Iterator<List<Object>>> {
        private static final int MAX_COLUMNS = 10;
        private final List<Object> beginningRow;
        private boolean[] hasLabels = new boolean[MAX_COLUMNS];
        private int labelIndex;
        private boolean parseFirstRow = true;
        private boolean isParsing;
        private int rowIndex = 1;
        private int colIndex = 1;

        EncounterParser(List<Object> beginningRow) {
            this.beginningRow = beginningRow;
        }

        @Override
        public void parseRows(Iterator<List<Object>> rows) {
            while (rows.hasNext()) {
                List<Object> row;
                if (parseFirstRow) {
                    parseFirstRow = false;
                    row = beginningRow;
                } else {
                    row = rows.next();
                }
                if (isBlankRow(row)) {
                    if (isParsing) {
                        return;
                    }
                } else {
                    isParsing = true;
                    // only parse labeled rows
                    if (isBlank(row.get(0))) {
                        continue;
                    }
                    beginMap(rowIndex++);
                    for (Object o : row) {
                        if (labelIndex == hasLabels.length) {
                            break;
                        }

                        if (row == beginningRow) {
                            if (isBlank(o)) {
                                hasLabels[labelIndex] = false;
                            } else {
                                hasLabels[labelIndex] = true;
                                addGridEntry(colIndex, o);
                            }
                        } else if (!isBlank(o) && hasLabels[labelIndex]) {
                            addGridEntry(colIndex, o);
                        }

                        ++labelIndex;
                        ++colIndex;
                    }
                    endMap();
                    colIndex = 1;
                    labelIndex = 0;
                }
            }
        }
    }

    String parse(String dateString, List<List<List<Object>>> rows) {
        beginMap(dateString);
        new RaidNameParser().parseRows(rows);
        endMap();
        return sb.toString();
    }

    private void beginEntry(Object o) {
        boolean isIndex = isIndex(o);
        sb.append('[');
        if (!isIndex) {
            sb.append('\"');
        }
        sb.append(o);
        if (!isIndex) {
            sb.append('\"');
        }
        sb.append(']');
    }

    private void beginMap(Object s) {
        beginEntry(s);
        sb.append("={");
    }

    private void addGridEntry(int key, Object value) {
        beginEntry(key);
        sb.append("=\"");
        // Replace any < 0x20 ASCII characters, or encoding breaks when read by addon.
        sb.append(String.valueOf(value).trim().replaceAll("[\u0000-\u001F]+", " "));
        sb.append("\",");
    }

    private void endMap() {
        sb.append("},");
    }

    private static boolean isBlankRow(List<Object> row) {
        return row == null || row.stream().allMatch(p -> p == null || p.toString().isEmpty());
    }

    private static boolean isBlank(Object o) {
        if (o == null) {
            return true;
        }
        char[] chars = o.toString().toCharArray();
        if (chars.length >= 2 && chars[0] == '-' && chars[1] == '-') {
            return true;
        }
        for (char c : chars) {
            if (c != ' ') {
                return false;
            }
        }
        return true;
    }

    private static boolean isIndex(Object o) {
        try {
            Integer.parseInt(String.valueOf(o));
        } catch (NumberFormatException e) {
            return false;
        }
        return true;
    }
}
