import { test, describe, before } from 'node:test';
import assert from 'node:assert';
import { initDatabase } from '../src/db/database';
import { VernacularSttService } from '../src/services/vernacularSttService';

describe('Real Speech-to-Text (STT) Vernacular Dialect Engine', () => {
  before(async () => {
    await initDatabase();
  });

  test('Step 1: Hindi (hi-IN) transcription extracts Flood, 4 people, Urgent status, and Boat need', async () => {
    const result = await VernacularSttService.transcribeAndExtract({
      language: 'hi-IN',
      transcriptHint: 'हम कंकड़बाग बाईपास के पास फंसे हैं, बाढ़ का पानी बढ़ रहा है, चार लोग हैं तुरंत नाव और दवा भेजिए'
    });

    assert.strictEqual(result.entities.category, 'FLOOD');
    assert.strictEqual(result.entities.urgency, 'CRITICAL');
    assert.strictEqual(result.entities.peopleCount, 4);
    assert.ok(result.entities.extractedNeeds.includes('rescue_boat'));
    assert.ok(result.entities.extractedNeeds.includes('medical_kit'));
    assert.ok(result.entities.locationName.includes('Kankarbagh'));
  });

  test('Step 2: Bhojpuri (bho-IN) dialect recognition parses water inundation and 3 people on roof', async () => {
    const result = await VernacularSttService.transcribeAndExtract({
      language: 'bho-IN',
      transcriptHint: 'हमार घर में चार फीट पानी भर गईल बा, हमनी के तीन गो लोग छत पर बा, तुरंत एगो नाव और पीने के पानी भेजो'
    });

    assert.ok(result.dialectDetected.includes('Bhojpuri'));
    assert.strictEqual(result.entities.category, 'FLOOD');
    assert.strictEqual(result.entities.peopleCount, 3);
    assert.ok(result.entities.extractedNeeds.includes('rescue_boat'));
    assert.ok(result.entities.extractedNeeds.includes('drinking_water'));
  });

  test('Step 3: Maithili (mai-IN) dialect recognition parses village distress and medical needs', async () => {
    const result = await VernacularSttService.transcribeAndExtract({
      language: 'mai-IN',
      transcriptHint: 'हमरा सभक गाम मे बाढ़िक पानि भरि गेल अछि, पाँच गोटे फँसल छी, भोजन आ दवाई तुरन्त चाही'
    });

    assert.ok(result.dialectDetected.includes('Maithili'));
    assert.strictEqual(result.entities.category, 'FLOOD');
    assert.strictEqual(result.entities.peopleCount, 5);
    assert.ok(result.entities.extractedNeeds.includes('food_packets'));
    assert.ok(result.entities.extractedNeeds.includes('medical_kit'));
  });

  test('Step 4: English (en-IN) distress statement parses medical casualty and ambulance urgency', async () => {
    const result = await VernacularSttService.transcribeAndExtract({
      language: 'en-IN',
      transcriptHint: 'SOS Emergency: Elder patient collapsed, high fever and unconscious, need ambulance and doctor immediately'
    });

    assert.strictEqual(result.entities.category, 'MEDICAL');
    assert.strictEqual(result.entities.urgency, 'CRITICAL');
    assert.ok(result.entities.extractedNeeds.includes('medical_kit'));
  });
});