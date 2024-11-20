/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot
import Files

internal struct RSSFeedGenerator<Site: Website> {
    let includedSectionIDs: Set<Site.SectionID>
    let itemPredicate: Predicate<Item<Site>>?
    let config: RSSFeedConfiguration
    let context: PublishingContext<Site>
    let date: Date

    func generate() async throws {
        let outputFile = try context.createOutputFile(at: config.targetPath)
        var items = [Item<Site>]()

        for sectionID in includedSectionIDs {
            items += context.sections[sectionID].items
        }

        items.sort { $0.date > $1.date }

        if let predicate = itemPredicate?.inverse() {
            items.removeAll(where: predicate.matches)
        }
        
        let feed = await makeFeed(containing: items).render(indentedBy: config.indentation)
        try outputFile.write(feed)
    }
}

private extension RSSFeedGenerator {
    struct Cache: Codable {
        let config: RSSFeedConfiguration
        let feed: String
        let itemCount: Int
    }

    func makeFeed(containing items: [Item<Site>]) async -> RSS {
        RSS(
            .title(context.site.name),
            .description(context.site.description),
            .link(context.site.url),
            .language(context.site.language),
            .lastBuildDate(date, timeZone: context.dateFormatter.timeZone),
            .pubDate(date, timeZone: context.dateFormatter.timeZone),
            .ttl(Int(config.ttlInterval)),
            .atomLink(context.site.url(for: config.targetPath)),
            .group(await items.prefix(config.maximumItemCount).concurrentMap { item in
                .item(
                    .guid(for: item, site: context.site),
                    .title(item.rssTitle),
                    .description(item.description),
                    .link(item.rssProperties.link ?? context.site.url(for: item)),
                    .pubDate(item.date, timeZone: context.dateFormatter.timeZone),
                    .content(for: item, site: context.site)
                )
            })
        )
    }
}
